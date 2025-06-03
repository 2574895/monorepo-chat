# monorepo-chat

Next-gen **AI Chat** monorepo containing

| Folder            | Description                                      | Stack                                   | Default Port |
| ----------------- | ------------------------------------------------ | --------------------------------------- | ------------ |
| `chat-front`      | Web UI built with **Next.js 15 + React 19**      | Tailwind CSS, Radix UI, LangGraph SDK   | `3000`       |
| `chat-back`       | API server that proxies/extends **LangGraph**    | FastAPI, LangChain, LangGraph, LangSmith| `8000`       |

The front-end speaks **exactly the same API** exposed by the official [`agent-chat-ui`](https://github.com/langchain-ai/agent-chat-ui) project – we just moved it behind a FastAPI proxy so you can:

* hide your **LangSmith API key**
* add **custom auth / business logic / DB calls**
* deploy UI & API separately or together

---

## 1. 빠른 시작

```bash
# 1. 저장소 클론
git clone <your-fork-url> monorepo-chat
cd monorepo-chat

# 2. .env 파일 생성 (백엔드 / 프론트엔드)
cp chat-back/.env chat-back/.env.local   # 혹은 직접 편집
cp chat-front/.env chat-front/.env.local # 혹은 직접 편집

# 3. 통합 개발 서버 실행
./run-dev.sh          # ↵ (백엔드 + 프론트 자동 실행)
```

* 프론트엔드 → `http://localhost:3000`
* 백엔드      → `http://localhost:8000/api`
* 헬스체크    → `http://localhost:8000/api/health`

---

## 2. 폴더 구조

```
monorepo-chat
├─ chat-front/          # Next.js UI
│  └─ …                 
├─ chat-back/           # FastAPI 서버
│  ├─ app/              
│  │  ├─ routers/       # chat.py, langgraph.py …
│  │  └─ main.py        # 애플리케이션 엔트리
│  ├─ requirements.txt
│  └─ .env
├─ run-dev.sh           # dev helper
└─ README.md            # ← you are here
```

---

## 3. 환경 변수

### 3.1 `chat-back/.env`

| 변수                       | 설명                                                                                 | 예시                          |
|--------------------------- |------------------------------------------------------------------------------------- |------------------------------ |
| `APP_ENV`                 | `development` / `production`                                                         | `development`                |
| `APP_HOST` `APP_PORT`     | 서버 주소·포트                                                                       | `0.0.0.0` `8000`             |
| `ALLOWED_ORIGINS`         | CORS 화이트리스트(COMMA)                                                             | `http://localhost:3000`      |
| **LangGraph 연결**        |                                                                                      |                               |
| `LANGGRAPH_API_URL`       | 여러분의 LangGraph 서버 base URL                                                     | `http://localhost:2024`      |
| **LangSmith (선택)**      |                                                                                      |                               |
| `LANGSMITH_API_KEY`       | 서버 측에서 LangGraph로 전달될 LangSmith 키                                          | `lsv2_xxxxxxxxx`             |
| **로깅**                  |                                                                                      |                               |
| `LOG_LEVEL`               | `DEBUG` `INFO` `WARNING` …                                                           | `INFO`                       |

> 백엔드가 실행되면 위 값을 사용해 LangGraph로 요청을 프록시하며,  
> 클라이언트는 **키 없이** `/api` 로만 통신합니다.

### 3.2 `chat-front/.env`

| 변수                    | 설명                                           | 예시                              |
|------------------------ |---------------------------------------------- |---------------------------------- |
| `NEXT_PUBLIC_API_URL`  | FastAPI 프록시 주소 (`/api` 포함)             | `http://localhost:8000/api`       |
| `NEXT_PUBLIC_ASSISTANT_ID` | LangGraph assistant/graph id               | `agent`                           |
| `NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP` | LangSmith 입력 폼 숨김          | `true`                            |
| `NEXT_PUBLIC_DISABLE_DEPLOYMENT_URL_SETUP` | 배포 URL 입력 폼 숨김       | `true`                            |

---

## 4. 개발 스크립트 상세

### 4.1 `./run-dev.sh`

* 백엔드
  * `python -m venv venv` → `pip install -r requirements.txt`
  * `uvicorn app.main:app --reload --port 8000`
* 프론트엔드
  * `pnpm|yarn|npm install`
  * `pnpm|yarn|npm run dev --port 3000`

종료는 `Ctrl + C`.

### 4.2 수동 실행

백엔드만:

```bash
cd chat-back
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

프론트엔드만:

```bash
cd chat-front
pnpm install
pnpm dev
```

---

## 5. LangGraph 서버 연결

1. **로컬 LangGraph**  
   ```bash
   uvicorn my_graph_app:app --port 2024
   ```  
   .env 의 `LANGGRAPH_API_URL=http://localhost:2024` 로 맞추면 됩니다.

2. **원격(클라우드) LangGraph**  
   `LANGGRAPH_API_URL` 에 배포 URL 입력, `LANGSMITH_API_KEY` 입력 후 재시작.

> FastAPI 프록시(`chat-back/app/routers/langgraph.py`)는  
> 모든 요청/스트림을 그대로 LangGraph에 전달하고, 필요시 `x-api-key` 헤더를 추가합니다.

---

## 6. Production 가이드

1. **프론트엔드** – Vercel / Netlify 등 정적 호스팅  
2. **백엔드** – Render / Fly.io / AWS ECS …
3. `ALLOWED_ORIGINS` 에 실제 도메인 추가
4. 환경 변수는 플랫폼 UI 나 Secret Manager 로 설정

---

## 7. Troubleshooting

| 문제                                  | 해결책 |
| ------------------------------------- | ------- |
| 403 / CORS 오류                       | `ALLOWED_ORIGINS` 확인 |
| LangGraph 502 / 연결 실패             | LangGraph 서버 실행 여부, `LANGGRAPH_API_URL` 확인 |
| 프론트에서 LangSmith 키 입력 요구     | `.env` 에 `NEXT_PUBLIC_DISABLE_LANGSMITH_SETUP=true` 확인 |

---

Happy Hacking! 🎉
