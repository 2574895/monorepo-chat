# Chat Backend Server

FastAPI 기반의 채팅 백엔드 서버입니다. LangGraph와 통합되어 있으며, 프론트엔드와의 통신을 위한 RESTful API를 제공합니다.

## 개발 환경 설정

1. 가상 환경 생성 및 활성화:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # 또는
   .\venv\Scripts\activate  # Windows
   ```

2. 의존성 설치:
   ```bash
   pip install -r requirements.txt
   ```

3. 환경 변수 설정:
   ```bash
   cp .env.example .env
   # .env 파일을 수정하여 필요한 설정을 입력하세요.
   ```

## 서버 실행

개발 모드로 실행:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API 문서

- Swagger UI: http://localhost:8000/api/docs
- ReDoc: http://localhost:8000/api/redoc

## 주요 엔드포인트

- `POST /api/chat/completions`: 채팅 완성 요청
- `GET /api/chat/models`: 사용 가능한 모델 목록 조회
- `GET /api/health`: 서버 상태 확인

## 배포

### Render 배포

1. Render 대시보드에서 새 Web Service 생성
2. GitHub 리포지토리 연결
3. 빌드 명령: `pip install -r requirements.txt`
4. 시작 명령: `uvicorn app.main:app --host 0.0.0.0 --port 10000`
5. 환경 변수 설정 (`.env` 파일 내용)

## 환경 변수

- `APP_ENV`: 실행 환경 (development/production)
- `APP_HOST`: 호스트 주소
- `APP_PORT`: 포트 번호
- `ALLOWED_ORIGINS`: 허용된 오리진 (쉼표로 구분)
- `LANGGRAPH_API_KEY`: LangGraph API 키
- `LANGGRAPH_API_BASE_URL`: LangGraph API 베이스 URL
