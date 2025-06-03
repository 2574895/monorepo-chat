# Railway 배포 가이드 – monorepo-chat

이 문서는 **monorepo-chat** 저장소의  
* Backend: `chat-back` (FastAPI)  
* Frontend: `chat-front` (Next.js 15)  

를 **Railway** 플랫폼에 각각 배포하는 전체 과정을 설명합니다.  
명령어·코드는 영어로 유지하고 설명만 한국어로 제공됩니다.

---

## 1. Railway 계정 설정 및 프로젝트 생성

1. [Railway](https://railway.app/) 웹사이트에서 GitHub 계정으로 로그인하거나 새 계정을 생성합니다.  
2. 대시보드 오른쪽 상단 **New Project** → **Deploy from GitHub repo** 선택.  
3. monorepo-chat 저장소를 연결하고 **Import** 버튼을 클릭합니다.  
4. 한 프로젝트 안에서 두 개의 서비스(backend, frontend)를 만들 예정이므로 **Project** 이름만 지정하고 완료합니다.

---

## 2. Backend(FastAPI) 서비스 배포

### 2-1. 서비스 생성

1. 프로젝트 내부 **New Service** → **Empty Service** 선택.  
2. **Service Name**: `chat-back` 입력.  
3. **Deployment Method**: **GitHub** → **monorepo-chat** 분기 `main` 선택.  
4. **Root Directory**: `chat-back` 입력.

### 2-2. 환경 변수(Environment Variables)

| Key | 예시 값 | 설명 |
|-----|---------|------|
| `PORT` | `8000` | uvicorn 기본 포트(변경 가능) |
| `LANGSMITH_API_KEY` | `...` | LangSmith 키 |
| `LANGGRAPH_SERVER_URL` | `https://api.langgraph.com` | LangGraph 엔드포인트 |

Railway 대시보드 → **Variables** 탭에서 추가합니다.

### 2-3. requirements.txt 확인

`chat-back/requirements.txt` 가 최신인지 확인하고 필요 패키지가 있으면 커밋 후 푸시합니다.

### 2-4. 배포 명령어

Railway **Settings → Deployments → Start Command** 에 다음 입력:

```
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 2-5. 도메인 설정

배포 완료 후 **Settings → Domains**  
`chat-back-production.up.railway.app` 와 같은 기본 도메인이 생성됩니다.  
커스텀 도메인을 연결하려면 **Add Domain** 클릭 후 DNS CNAME 을 지정합니다.

---

## 3. Frontend(Next.js) 서비스 배포

### 3-1. 서비스 생성

1. **New Service** → **Empty Service**  
2. **Service Name**: `chat-front`  
3. **Deployment Method**: **GitHub** → 동일 리포지토리 `main`  
4. **Root Directory**: `chat-front`

### 3-2. 환경 변수

| Key | 예시 값 | 설명 |
|-----|---------|------|
| `NEXT_PUBLIC_BACKEND_URL` | `https://chat-back-production.up.railway.app` | FastAPI 엔드포인트 |
| `NEXT_PUBLIC_LANGGRAPH_ASSISTANT_ID` | `12345678` | 사용 중인 어시스턴트 ID |
| 기타 | … | 필요한 추가 변수 |

### 3-3. package.json 확인

`chat-front/package.json` 의 **scripts** 항목이 다음과 같은지 점검:

```json
"scripts": {
  "build": "next build",
  "start": "next start -p $PORT"
}
```

### 3-4. 빌드 설정

Railway **Settings → Deployments → Build Command**

```
pnpm install --frozen-lockfile
pnpm build
```

**Start Command**

```
pnpm start
```

※ npm 또는 yarn 을 사용한다면 명령어를 맞게 변경하세요.

### 3-5. 도메인 설정

배포 완료 후 기본 도메인 `chat-front-production.up.railway.app` 생성.  
커스텀 도메인은 **Add Domain** 에서 추가하고 DNS CNAME 설정.

---

## 4. 배포 후 연결 설정

1. Frontend에서 Backend URL을 올바르게 가리키도록  
   `NEXT_PUBLIC_BACKEND_URL` 을 Backend 서비스 도메인으로 설정했는지 확인합니다.  
2. CORS: `chat-back/app/main.py` 에서 `origins=["*"]` 혹은 프론트 도메인만 허용하도록 수정 가능합니다.  
3. 변경 후 **Redeploy** 버튼을 눌러 두 서비스 모두 다시 배포합니다.

---

## 5. 트러블슈팅 가이드

| 증상 | 원인 및 해결 |
|------|-------------|
| 404 /api 요청 실패 | Backend 도메인 오타 또는 CORS 차단. 환경 변수 확인. |
| Backend 배포 실패 (ModuleNotFoundError) | requirements.txt 누락 패키지 추가 후 재배포. |
| Frontend 빌드 오류(ESLint) | `NEXT_DISABLE_LINTING=1` 변수를 추가하거나 코드 수정. |
| 메모리 초과 | Railway **Metrics** 확인 후 **RAM** 플랜 업그레이드. |
| 커스텀 도메인 접속 불가 | DNS 전파 대기(최대 48h) 또는 CNAME 설정 확인. |

---

## 6. 모니터링 및 로그 확인

### 6-1. 실시간 로그

- 프로젝트 → 서비스 선택 → **Logs** 탭  
  - Backend: API 요청·에러 로그  
  - Frontend: Next.js 빌드·런타임 로그

### 6-2. Metrics

- **Metrics** 탭에서 CPU, RAM, 네트워크 사용량 시각화  
- 알림 설정: **Settings → Notifications** 에서 Slack, Discord, Email 연동 가능

### 6-3. 배포 히스토리 및 롤백

- **Deployments** 탭에서 각 커밋별 배포 기록 확인  
- 문제가 발생하면 원하는 배포 옆 **Roll Back** 클릭

---

## 부록: 로컬 테스트 스크립트

```bash
# backend
cd chat-back
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# frontend
cd ../chat-front
pnpm install
pnpm dev
```

로컬에서 정상 작동을 확인한 후 GitHub에 푸시하면 Railway가 자동으로 재배포합니다.

---

배포가 완료되면 `https://<custom-front-domain>/` 로 접속하여  
AI 챗 애플리케이션이 정상 동작하는지 확인하세요.  
즐거운 개발 되십시오! 🚀
