#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 스크립트 실행 디렉토리로 이동
cd "$(dirname "$0")"

echo -e "${BLUE}=== monorepo-chat 개발 환경 실행 ===${NC}"

# 환경 변수 파일 확인
if [ ! -f chat-back/.env ]; then
    echo -e "${YELLOW}⚠️  chat-back/.env 파일이 없습니다.${NC}"
    echo -e "${YELLOW}예제 파일을 복사하거나 새로 생성해주세요.${NC}"
    exit 1
fi

if [ ! -f chat-front/.env ]; then
    echo -e "${YELLOW}⚠️  chat-front/.env 파일이 없습니다.${NC}"
    echo -e "${YELLOW}예제 파일을 복사하거나 새로 생성해주세요.${NC}"
    exit 1
fi

# 종료 시 모든 프로세스 정리
cleanup() {
    echo -e "\n${RED}개발 서버를 종료합니다...${NC}"
    kill $(jobs -p) 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# 백엔드 서버 실행 함수
run_backend() {
    echo -e "${GREEN}🔧 백엔드 서버 시작 중...${NC}"
    cd chat-back
    
    # 가상 환경 확인 및 생성
    if [ ! -d "venv" ]; then
        echo -e "${CYAN}가상 환경을 생성합니다...${NC}"
        python -m venv venv
    fi
    
    # 가상 환경 활성화
    source venv/bin/activate || source venv/Scripts/activate
    
    # 의존성 설치
    echo -e "${CYAN}필요한 패키지를 설치합니다...${NC}"
    pip install -r requirements.txt
    
    # 서버 실행
    echo -e "${GREEN}🚀 FastAPI 백엔드 서버를 시작합니다...${NC}"
    echo -e "${GREEN}📡 서버 주소: http://localhost:8000${NC}"
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    
    cd ..
}

# 프론트엔드 서버 실행 함수
run_frontend() {
    echo -e "${PURPLE}🔧 프론트엔드 서버 시작 중...${NC}"
    cd chat-front
    
    # 의존성 설치
    echo -e "${CYAN}필요한 패키지를 설치합니다...${NC}"
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm install
    elif [ -f "yarn.lock" ]; then
        yarn install
    else
        npm install
    fi
    
    # 서버 실행
    echo -e "${PURPLE}🚀 Next.js 프론트엔드 서버를 시작합니다...${NC}"
    echo -e "${PURPLE}📡 서버 주소: http://localhost:3000${NC}"
    if [ -f "pnpm-lock.yaml" ]; then
        pnpm dev
    elif [ -f "yarn.lock" ]; then
        yarn dev
    else
        npm run dev
    fi
    
    cd ..
}

# 백엔드와 프론트엔드 병렬 실행
echo -e "${CYAN}백엔드와 프론트엔드 서버를 시작합니다...${NC}"
echo -e "${YELLOW}종료하려면 Ctrl+C를 누르세요.${NC}"

# 백그라운드에서 백엔드 실행
run_backend &
BACKEND_PID=$!

# 약간의 지연 후 프론트엔드 실행
sleep 2
run_frontend &
FRONTEND_PID=$!

# 모든 자식 프로세스가 종료될 때까지 대기
wait $BACKEND_PID $FRONTEND_PID
