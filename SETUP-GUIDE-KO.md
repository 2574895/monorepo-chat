# 💻 monorepo-chat 로컬 설정 가이드 (한국어)

이 문서는 **chat-front(Next.js)** 와 **chat-back(FastAPI)** 가 포함된 모노레포를 로컬에서 즉시 실행할 수 있도록 단계별 설정 방법을 안내합니다.  
또한 **환경 변수**, **CORS 설정**, **개발 서버 실행/종료 방법**을 상세히 다룹니다.

---

## 1. 선행 조건

| 필수 항목 | 버전 예시 | 확인 명령 |
|-----------|----------|-----------|
| **Python** | ≥ 3.9    | `python --version` |
| **Node.js** | ≥ 18     | `node -v` |
| **pnpm**<br>(or npm/yarn) | ≥ 8      | `pnpm -v` |
| **Git** | 최신       | `git --version` |

---

## 2. 레포지토리 클론

```bash
git clone <your-fork-url> monorepo-chat
cd monorepo-chat
```

---

## 3. 환경 변수 설정

### 3.1 chat-back / `.env`

아래 예시를 기준으로 `chat-back/.env` 파일을 만듭니다.  
필요 시 값을 수정하세요.

```dotenv
# ========= 서버 =========
APP_ENV=development            # development / production
APP_HOST=0.0.0.0
APP_PORT=8000

# ========= CORS =========
# 쉼표(,)로 여러 오리진 지정
ALLOWED_ORIGINS=http://localhost:3000

# ========= LangGraph =========
LANGGRAPH_API_URL=http://localhost:2024

# ========= LangSmith (선택) =========
LANGSMITH_API_KEY=             # 배포 시에만 사용

# ========= 로깅 =========
LOG_LEVEL=INFO
```

> 🔔 **ALLOWED_ORIGINS**  
> `chat-front`가 구동되는 주소(기본: `http://localhost:3000`)를 포함해야 브라우저 CORS 오류가 발생하지 않습니다.  
> 배포 시 실제 도메인을 추가하세요.

### 3.2 chat-front / `.env`

```dotenv
# ========= chat-front =========
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_ASSISTANT_ID=agent

# LangSmith / 배포 URL 입력 폼 숨김
NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true
NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP=true
```

---

## 4. CORS 설정 원리

`chat-back/app/main.py` 에서 FastAPI의 `CORSMiddleware`가 적용되어 있습니다.

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

* `.env` 의 **ALLOWED_ORIGINS** 값이 리스트로 분리되어 허용 오리진으로 등록됩니다.
* 로컬 개발 시 `http://localhost:3000` 만으로 충분하지만,  
  프로덕션에서는 각 프론트엔드 도메인을 쉼표로 추가해야 합니다.

---

## 5. 로컬 개발 환경 실행

### 5.1 통합 실행 스크립트 (추천)

```bash
./run-dev.sh
```

스크립트가 수행하는 작업  
1. **chat-back**
   * Python 가상환경(`venv`) 생성
   * `pip install -r chat-back/requirements.txt`
   * `uvicorn app.main:app --reload --port 8000`
2. **chat-front**
   * `pnpm install` (없으면 npm/yarn)
   * `pnpm dev --port 3000`

종료는 터미널에서 **Ctrl + C**.

### 5.2 수동 실행

두 개의 터미널 탭을 엽니다.

**백엔드**

```bash
cd chat-back
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**프론트엔드**

```bash
cd chat-front
pnpm install   # or npm install / yarn
pnpm dev --port 3000
```

---

## 6. 실행 확인

| 항목 | URL |
|------|-----|
| 프론트엔드 UI | http://localhost:3000 |
| FastAPI Swagger | http://localhost:8000/docs |
| 헬스체크 | http://localhost:8000/api/health |

브라우저에서 UI를 열고 **Deployment URL / LangSmith Key** 입력 화면이 **보이지 않아야** 정상적으로 프록시가 작동 중인 것입니다.

---

## 7. 자주 발생하는 문제

| 증상 | 해결 방법 |
|------|-----------|
| `CORS policy` 오류 | `chat-back/.env` → ALLOWED_ORIGINS 값 확인 |
| 프론트에서 LangSmith 키 입력 요구 | `chat-front/.env` 의 `NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true` 확인 |
| LangGraph 연결 실패 | LangGraph 서버 기동 여부 및 `LANGGRAPH_API_URL` 확인 |
| 404 /api 오류 | FastAPI가 실행 중인지, 포트 설정이 맞는지 확인 |

---

## 8. 다음 단계

* LangGraph 서버를 로컬 또는 클라우드에 배포  
* 프로덕션 환경 변수(도메인, API 키) 업데이트  
* `Dockerfile` 또는 CI 파이프라인 구성

---

즐거운 개발 되세요! 🚀
