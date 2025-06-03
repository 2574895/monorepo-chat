# Railway 환경 변수 설정 가이드

본 문서는 두 개의 Railway 서비스  
`back-production-1bef.up.railway.app` (Backend)  
`front-production-7b09.up.railway.app` (Frontend)  
에 필요한 **환경 변수(Environment Variables)** 를 설정하는 방법을 안내합니다.

---

## 1. Backend 서비스 (`chat-back`)

| Key | 예시 값 | 설명 |
|-----|---------|------|
| `PORT` | `8000` | uvicorn 실행 포트 |
| `ALLOWED_ORIGINS` | `https://front-production-7b09.up.railway.app,http://localhost:3000` | CORS 허용 도메인(쉼표 구분) |
| `LANGSMITH_API_KEY` | `sk-xxxxxxxx` | LangSmith API Key (필수) |
| `LANGGRAPH_API_URL` | `https://api.langgraph.com` | LangGraph 서버 URL |
| `APP_ENV` | `production` | 실행 환경(production / development 등) |

> 🔐 **주의**: `LANGSMITH_API_KEY` 등 민감 정보는 외부에 노출되지 않도록 합니다.

---

## 2. Frontend 서비스 (`chat-front`)

| Key | 예시 값 | 설명 |
|-----|---------|------|
| `NEXT_PUBLIC_BACKEND_URL` | `https://back-production-1bef.up.railway.app` | FastAPI 백엔드 엔드포인트 |
| `NEXT_PUBLIC_LANGGRAPH_ASSISTANT_ID` | `abc123` | LangGraph Assistant ID |

> `NEXT_PUBLIC_` 접두사는 Next.js 빌드 시 클라이언트에게 공개됩니다.

---

## 3. Railway 대시보드에서 변수 설정하기

1. **프로젝트** > 원하는 **Service** 선택  
2. 왼쪽 메뉴 **Variables** 탭 클릭  
3. 우측 상단 **+ New Variable** 버튼  
4. `Key` 와 `Value` 입력 후 **Add**  
   - 여러 변수 입력 시 **Bulk Add** 기능 사용 가능 (`KEY=VALUE` 형식 한 줄씩 입력)
5. 모든 변수 추가 후 **Deploy** 탭에서 **Redeploy** 버튼을 눌러 변경 적용

### 팁
- 변수 값 수정 → 저장하면 **자동 재배포** 옵션이 나타납니다. 즉시 적용하려면 **Yes, redeploy** 선택
- 민감한 값은 **Mask** 아이콘을 눌러 가림 처리
- `.env.production` 파일을 커밋하지 말고 Railway Variables로만 관리

---

## 4. 배포 후 점검

1. **Backend**  
   - `https://back-production-1bef.up.railway.app/api/health` 응답이 `{ "status": "ok" }` 인지 확인
2. **Frontend**  
   - 웹 브라우저에서 `https://front-production-7b09.up.railway.app` 접속  
   - 콘솔 에러 없이 챗 인터페이스가 작동하는지 확인

---

## 5. 문제 해결

| 증상 | 점검 항목 |
|------|-----------|
| 401/403 CORS 에러 | `ALLOWED_ORIGINS` 값에 프론트 도메인 포함 여부 |
| 404 `/api/chat` | `NEXT_PUBLIC_BACKEND_URL` 오타 여부, Backend 재배포 여부 |
| LangGraph 연결 실패 | `LANGGRAPH_API_URL` 정확성 및 방화벽 설정 |
| 환경 변수 변경 적용 안 됨 | 변수 저장 후 **Redeploy** 수행 여부 |

---

이 가이드를 따라 환경 변수를 올바르게 설정하면  
Frontend ↔️ Backend ↔️ LangGraph 간 통신이 정상 동작합니다.  
문제가 지속되면 Railway Logs & Metrics 탭을 확인하세요.
