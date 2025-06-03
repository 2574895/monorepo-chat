# 🚀 Vercel + Render 배포 가이드 (한국어)

`monorepo-chat` 프로젝트를 **Vercel(프론트엔드)** 과 **Render(백엔드)** 에 배포하는 전체 절차를 정리했습니다.  
순차적으로 따라 하면 무중단으로 서비스 오픈이 가능합니다.

---

## 0. 준비 사항

| 항목 | 내용 |
|------|------|
| GitHub 저장소 | Vercel·Render 모두 GitHub 연동으로 배포 |
| 커스텀 도메인(선택) | ex) `chat.example.com`, `api.example.com` |
| LangGraph 서버 | 자체 호스팅 또는 LangGraph Cloud URL |

---

## 1. 백엔드(Render) 먼저 배포

> **왜 먼저?**  
> 프론트가 초기 로드에서 API 호출을 하기 때문에 **API URL** 이 선행되어야 합니다.

### 1-1. Render Web Service 생성

1. Render 대시보드 → **New → Web Service**  
2. GitHub 저장소 선택 → `chat-back` 경로 자동 감지
3. **Environment**  
   - **Build Command**:  
     ```bash
     pip install -r chat-back/requirements.txt
     ```
   - **Start Command**:  
     ```bash
     uvicorn app.main:app --host 0.0.0.0 --port 10000
     ```
4. **Instance Type**: Starter(무료) or Standard  
5. **Runtime** → `Python 3.11` 선택

### 1-2. 환경 변수(.env → Render ⬇︎)

| Key | 예시 값 | 설명 |
|-----|---------|------|
| APP_ENV | production |
| APP_PORT | 10000 |
| ALLOWED_ORIGINS | https://\<vercel-domain\>.vercel.app,https://chat.example.com |
| LANGGRAPH_API_URL | https://my-graph.langgraph.app |
| LANGSMITH_API_KEY | lsv2_xxxxxx _(선택)_ |
| LOG_LEVEL | INFO |

> **ALLOWED_ORIGINS**: Vercel 기본 도메인과 (있다면) 커스텀 도메인 모두 쉼표로 등록.

### 1-3. 디플로이 & 확인

- URL 예시: `https://chat-back-xxxxx.onrender.com`  
- 헬스 체크: `GET https://.../api/health` → `{ "status": "ok" }`

---

## 2. 프론트엔드(Vercel) 배포

### 2-1. Vercel 프로젝트 생성

1. Vercel 대시보드 → **Add New → Project**
2. GitHub 저장소 선택 → **Framework** 자동 `Next.js`

### 2-2. 빌드 설정

| 항목 | 값 |
|------|----|
| **Framework Preset** | Next.js |
| **Build Command** | 자동 *(pnpm 사용 시)* |
| **Install Command** | `pnpm install --frozen-lockfile` |
| **Output Dir** | `.vercel/output` *(자동)* |

### 2-3. 환경 변수(.env → Vercel ⬇︎)

| Key | 예시 값 |
|-----|----------|
| NEXT_PUBLIC_API_URL | https://chat-back-xxxxx.onrender.com/api |
| NEXT_PUBLIC_ASSISTANT_ID | agent |
| NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP | true |
| NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP | true |

> **주의:** `NEXT_PUBLIC_API_URL` 은 반드시 `/api` 까지 포함.

### 2-4. 배포 & 확인

- Vercel Preview URL 예시: `https://monorepo-chat.vercel.app`
- 첫 화면에서 LangGraph/키 입력 폼이 보이지 않아야 정상.

---

## 3. 커스텀 도메인 연결(선택)

### 3-1. 백엔드 도메인

1. Render → **Settings → Custom Domains → Add**  
2. `api.chat.example.com` 입력  
3. DNS에 `CNAME` → Render 제공값으로 설정  
4. SSL 인증서 자동 발급 확인

### 3-2. 프론트엔드 도메인

1. Vercel → **Settings → Domains → Add**  
2. `chat.example.com` 입력  
3. DNS에 `CNAME` → Vercel 제공값으로 설정  
4. 배포 도메인이 `chat.example.com` 이 되면 **NEXT_PUBLIC_API_URL** 을
   `https://api.chat.example.com/api` 로 업데이트 → 다시 배포

---

## 4. 배포 순서 TL;DR

1. **Render** Web Service 생성 → 환경 변수 입력 → 배포 완료  
2. Render URL 획득 → **NEXT_PUBLIC_API_URL** 값으로 준비  
3. **Vercel** 프로젝트 생성 → 환경 변수 입력 → 배포 완료  
4. (선택) 커스텀 도메인 연결 → 변수 업데이트 후 재배포

---

## 5. 운영 체크리스트

| 항목 | 확인 방법 |
|------|-----------|
| CORS 오류 없음 | 브라우저 콘솔 Network 탭 |
| API 200 응답 | `/api/health` |
| HTTPS 강제 | Render, Vercel 기본 적용 |
| LangGraph 연결 | 백엔드 로그에 “LangGraph API is available” |

---

## 6. 장애 대응

| 증상 | 원인·해결 |
|------|-----------|
| 403 CORS | ALLOWED_ORIGINS 누락 → Render 환경 변수 수정 |
| 프론트에서 LangSmith 키 입력 요구 | NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true 확인 |
| 502 /api 호출 실패 | Render 서비스 다운, LANGGRAPH_API_URL 오타 |

---

배포 후에도 **Render → Events**, **Vercel → Deployments** 로그로 실시간 상태를 모니터링하면 안정적인 운영이 가능합니다.  
Happy Deployment! 🌈
