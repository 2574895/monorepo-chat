#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 스크립트 실행 디렉토리로 이동
cd "$(dirname "$0")/.."
ROOT_DIR=$(pwd)

echo -e "${BLUE}=== 프로덕션 URL 업데이트 도구 ===${NC}"
echo -e "이 스크립트는 배포 후 실제 URL로 환경 변수를 업데이트합니다.\n"

# 백엔드 URL 입력 받기
read -p "$(echo -e "${YELLOW}Render 백엔드 URL을 입력하세요${NC} (예: https://chat-back-xxxxx.onrender.com): ")" BACKEND_URL

# 백엔드 URL 유효성 검사
if [[ ! $BACKEND_URL =~ ^https?:// ]]; then
  echo -e "${RED}오류: URL은 http:// 또는 https://로 시작해야 합니다.${NC}"
  exit 1
fi

# 프론트엔드 URL 입력 받기
read -p "$(echo -e "${YELLOW}Vercel 프론트엔드 URL을 입력하세요${NC} (예: https://chat-front-xxxxx.vercel.app): ")" FRONTEND_URL

# 프론트엔드 URL 유효성 검사
if [[ ! $FRONTEND_URL =~ ^https?:// ]]; then
  echo -e "${RED}오류: URL은 http:// 또는 https://로 시작해야 합니다.${NC}"
  exit 1
fi

# 커스텀 도메인 사용 여부 확인
read -p "$(echo -e "${YELLOW}커스텀 도메인을 사용하시나요?${NC} (y/n): ")" USE_CUSTOM_DOMAIN

if [[ $USE_CUSTOM_DOMAIN =~ ^[Yy] ]]; then
  read -p "$(echo -e "${YELLOW}백엔드 커스텀 도메인을 입력하세요${NC} (예: https://api.example.com): ")" BACKEND_CUSTOM_DOMAIN
  read -p "$(echo -e "${YELLOW}프론트엔드 커스텀 도메인을 입력하세요${NC} (예: https://chat.example.com): ")" FRONTEND_CUSTOM_DOMAIN
  
  # 커스텀 도메인 유효성 검사
  if [[ ! $BACKEND_CUSTOM_DOMAIN =~ ^https?:// ]] || [[ ! $FRONTEND_CUSTOM_DOMAIN =~ ^https?:// ]]; then
    echo -e "${RED}오류: 커스텀 도메인은 http:// 또는 https://로 시작해야 합니다.${NC}"
    exit 1
  fi
  
  # 실제 사용할 URL 설정
  ACTUAL_BACKEND_URL=$BACKEND_CUSTOM_DOMAIN
  ACTUAL_FRONTEND_URL=$FRONTEND_CUSTOM_DOMAIN
  ALLOWED_ORIGINS="$FRONTEND_URL,$FRONTEND_CUSTOM_DOMAIN"
else
  ACTUAL_BACKEND_URL=$BACKEND_URL
  ACTUAL_FRONTEND_URL=$FRONTEND_URL
  ALLOWED_ORIGINS=$FRONTEND_URL
fi

echo -e "\n${CYAN}=== 환경 변수 파일 업데이트 중... ===${NC}"

# 1. chat-back/.env.production 파일 업데이트
BACKEND_ENV_FILE="$ROOT_DIR/chat-back/.env.production"

if [ -f "$BACKEND_ENV_FILE" ]; then
  # ALLOWED_ORIGINS 업데이트
  sed -i.bak "s|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=$ALLOWED_ORIGINS|g" "$BACKEND_ENV_FILE"
  echo -e "${GREEN}✓ $BACKEND_ENV_FILE 파일의 ALLOWED_ORIGINS를 업데이트했습니다.${NC}"
else
  echo -e "${YELLOW}⚠️ $BACKEND_ENV_FILE 파일이 없습니다. 새로 생성합니다.${NC}"
  cat > "$BACKEND_ENV_FILE" << EOF
# Server Configuration
APP_ENV=production
APP_HOST=0.0.0.0
APP_PORT=10000

# CORS
ALLOWED_ORIGINS=$ALLOWED_ORIGINS

# LangGraph Configuration
# 실제 LangGraph 서버 URL로 교체해야 합니다
LANGGRAPH_API_URL=https://your-langgraph-server.langgraph.app

# LangSmith Configuration
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=
LANGCHAIN_PROJECT=chat-production
LANGCHAIN_TRACING_V2=true

# Logging
LOG_LEVEL=INFO
EOF
  echo -e "${GREEN}✓ $BACKEND_ENV_FILE 파일을 생성했습니다.${NC}"
fi

# 2. chat-front/.env.production 파일 업데이트
FRONTEND_ENV_FILE="$ROOT_DIR/chat-front/.env.production"

if [ -f "$FRONTEND_ENV_FILE" ]; then
  # NEXT_PUBLIC_API_URL 업데이트
  sed -i.bak "s|NEXT_PUBLIC_API_URL=.*|NEXT_PUBLIC_API_URL=${ACTUAL_BACKEND_URL}/api|g" "$FRONTEND_ENV_FILE"
  echo -e "${GREEN}✓ $FRONTEND_ENV_FILE 파일의 NEXT_PUBLIC_API_URL을 업데이트했습니다.${NC}"
else
  echo -e "${YELLOW}⚠️ $FRONTEND_ENV_FILE 파일이 없습니다. 새로 생성합니다.${NC}"
  cat > "$FRONTEND_ENV_FILE" << EOF
# Vercel 배포용 프로덕션 환경 변수

# 백엔드 API URL (Render 배포 URL)
# 주의: 반드시 /api 경로까지 포함해야 함
NEXT_PUBLIC_API_URL=${ACTUAL_BACKEND_URL}/api

# LangGraph 에이전트/그래프 ID
NEXT_PUBLIC_ASSISTANT_ID=agent

# LangSmith 설정 화면 비활성화 (백엔드에서 API 키 처리)
NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true

# 배포 URL 설정 화면 비활성화 (백엔드에서 LangGraph API URL 처리)
NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP=true

# 프로덕션 모드 설정
NODE_ENV=production
EOF
  echo -e "${GREEN}✓ $FRONTEND_ENV_FILE 파일을 생성했습니다.${NC}"
fi

# 3. vercel.json 파일 업데이트
VERCEL_JSON_FILE="$ROOT_DIR/vercel.json"

if [ -f "$VERCEL_JSON_FILE" ]; then
  # rewrites 섹션의 destination 업데이트
  sed -i.bak "s|\"destination\": \"https://.*\.onrender\.com/api/:path\*\"|\"destination\": \"${ACTUAL_BACKEND_URL}/api/:path*\"|g" "$VERCEL_JSON_FILE"
  echo -e "${GREEN}✓ $VERCEL_JSON_FILE 파일의 rewrites 섹션을 업데이트했습니다.${NC}"
else
  echo -e "${YELLOW}⚠️ $VERCEL_JSON_FILE 파일이 없습니다. 새로 생성합니다.${NC}"
  cat > "$VERCEL_JSON_FILE" << EOF
{
  "buildCommand": "cd chat-front && pnpm install --frozen-lockfile && pnpm build",
  "outputDirectory": "chat-front/.vercel/output",
  "devCommand": "cd chat-front && pnpm dev",
  "installCommand": "cd chat-front && pnpm install --frozen-lockfile",
  "framework": "nextjs",
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "${ACTUAL_BACKEND_URL}/api/:path*"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ],
  "env": {
    "NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP": "true",
    "NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP": "true",
    "NEXT_PUBLIC_ASSISTANT_ID": "agent"
  }
}
EOF
  echo -e "${GREEN}✓ $VERCEL_JSON_FILE 파일을 생성했습니다.${NC}"
fi

# 백업 파일 정리
find "$ROOT_DIR" -name "*.bak" -type f -delete

echo -e "\n${GREEN}=== 모든 설정 파일이 성공적으로 업데이트되었습니다! ===${NC}"
echo -e "다음 단계:"
echo -e "1. ${CYAN}git add . && git commit -m \"Update production URLs\"${NC}"
echo -e "2. ${CYAN}git push${NC} 로 변경 사항을 저장소에 푸시"
echo -e "3. Render와 Vercel에서 재배포 트리거 (자동 배포가 설정되어 있다면 자동으로 진행됨)"
echo -e "\n${YELLOW}참고:${NC} LangGraph 서버 URL은 직접 확인하고 필요시 수정해야 합니다."
echo -e "chat-back/.env.production 파일의 LANGGRAPH_API_URL 값을 확인하세요.\n"
