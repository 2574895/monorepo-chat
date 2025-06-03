# ✅ DEPLOYMENT CHECKLIST

모노레포 **chat-front(Next.js) + chat-back(FastAPI)** 를  
**Vercel + Render** 조합으로 프로덕션에 무중단 배포할 때 단계별로 확인해야 할 사항을 정리했습니다.

---

## 0. 사전 준비

- [ ] GitHub 저장소 **main/master 브랜치** 최신 상태 확인
- [ ] **LangGraph 서버 URL** 확보 (`LANGGRAPH_API_URL`)
- [ ] (선택) **LangSmith API KEY** 발급
- [ ] Vercel & Render 계정에 **빌드 크레딧**/카드 등록

---

## 1. 백엔드 ‑ Render

### 1-1. 서비스 생성

- [ ] Render **Web Service** → GitHub 연결
- [ ] 경로가 `chat-back/` 로 잡혀 있는지 확인
- [ ] **Python 3.11** 런타임 선택
- [ ] Build Command  
  `pip install -r chat-back/requirements.txt`
- [ ] Start Command  
  `uvicorn app.main:app --host 0.0.0.0 --port 10000`
- [ ] Health Check Path `/api/health`
- [ ] Instance Type 적절히 선택 (Starter → PoC, Standard 이상 → 실서비스)

### 1-2. 환경 변수 입력

| Key | 메모 |
|-----|------|
| `APP_ENV=production` | |
| `APP_PORT=10000` | Render 포트와 일치 |
| `ALLOWED_ORIGINS` | Vercel 기본/커스텀 도메인 모두 쉼표로 |
| `LANGGRAPH_API_URL` | 실제 LangGraph 서버 |
| `LANGSMITH_API_KEY` | 필요 시 |
| `LOG_LEVEL=INFO` | |

- [ ] 입력 후 **Save Changes** 클릭

### 1-3. 최초 배포 & 검증

- [ ] Deploy 로그 `EXIT STATUS 0` 확인
- [ ] `GET <render-url>/api/health` → `{ "status": "ok" }`
- [ ] CORS 헤더에 `Access-Control-Allow-Origin` 포함 확인

---

## 2. 프론트엔드 ‑ Vercel

### 2-1. 프로젝트 생성

- [ ] GitHub 저장소 연결 → `chat-front` 디렉토리 자동 감지
- [ ] 프레임워크 Preset: **Next.js**
- [ ] Install Command `pnpm install --frozen-lockfile`
- [ ] Build Command 자동 (`pnpm build`)
- [ ] Output Dir `.vercel/output`

### 2-2. 환경 변수 입력

| Key | 예시 |
|-----|------|
| `NEXT_PUBLIC_API_URL=https://<render-url>/api` | `/api` 포함 필수 |
| `NEXT_PUBLIC_ASSISTANT_ID=agent` | |
| `NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true` | |
| `NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP=true` | |

- [ ] 입력 후 **Save & Deploy**

### 2-3. 최초 배포 & 검증

- [ ] 빌드 성공 (`NEXT BUILD COMPLETED`)
- [ ] Preview URL 접속 → 첫 화면에서 **설정 폼 안 나오는지** 확인
- [ ] DevTools Network 탭: `/api/health` 호출 200

---

## 3. 커스텀 도메인 (선택)

### 3-1. Render

- [ ] **api.example.com** 도메인 추가
- [ ] DNS CNAME → Render 제공값 설정
- [ ] HTTPS 인증서 **Ready**

### 3-2. Vercel

- [ ] **chat.example.com** 도메인 추가
- [ ] DNS CNAME → Vercel 제공값 설정
- [ ] SSL 인증 완료
- [ ] `NEXT_PUBLIC_API_URL` → `https://api.example.com/api` 로 변경 후 재배포

---

## 4. 최종 Smoke Test

- [ ] **UI 로드** 속도 정상 (Lighthouse ≥ 80)
- [ ] **새 대화 생성 → 응답 수신** OK
- [ ] **파일 업로드**(PDF, 이미지) 동작
- [ ] **인증/키** 노출 없음 (DevTools → Headers)
- [ ] 모바일 뷰 기능 확인

---

## 5. 모니터링 & 롤백

- [ ] Render **Events & Metrics** 오류 0 확인
- [ ] Vercel **Deployments** 2xx 비율 100%
- [ ] Sentry / Logtail 등 오류 알림 설정
- [ ] 문제 발생 시 Vercel **Previous Deployment**로 Rollback 가능

---

## 6. 체크 완료 후 태그 / 릴리스

- [ ] `git tag vX.Y.Z -m "Prod release"` → GitHub Push
- [ ] GitHub Release 노트 작성 (변경 내역, Known issues)

---

이 체크리스트를 모두 완료하면 **무중단·안전 배포**가 보장됩니다.  
행복한 배포 되세요! 🚀
