import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from dotenv import load_dotenv
from datetime import datetime
import httpx

# 환경 변수 로드
load_dotenv()

# 로깅 설정
logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO")),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# LangSmith 로거 설정
langsmith_logger = logging.getLogger("langsmith")
langsmith_logger.setLevel(logging.DEBUG)

app = FastAPI(
    title="Chat Backend API",
    description="LangChain + FastAPI Chat Backend",
    version="1.0.0",
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "https://front-production-7b09.up.railway.app,http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 라우터 임포트 및 등록
from app.routers import chat
app.include_router(chat.router, prefix="/api/chat", tags=["chat"])

# LangGraph 라우터 임포트 및 등록
from app.routers import langgraph
app.include_router(langgraph.router, prefix="/api", tags=["langgraph"])

# LangGraph API 상태 확인 함수
async def check_langgraph_api():
    """LangGraph API 연결 상태를 확인합니다."""
    langgraph_api_url = os.getenv("LANGGRAPH_API_URL")
    if not langgraph_api_url:
        logger.warning("LANGGRAPH_API_URL is not set")
        return False
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{langgraph_api_url}/health", timeout=5.0)
            if response.status_code == 200:
                logger.info("LangGraph API is available")
                return True
            else:
                logger.warning(f"LangGraph API returned status code {response.status_code}")
                return False
    except Exception as e:
        logger.error(f"Error connecting to LangGraph API: {str(e)}")
        return False

@app.on_event("startup")
async def startup_event():
    """애플리케이션 시작 시 실행"""
    logger.info("Starting up application...")
    logger.info(f"Environment: {os.getenv('APP_ENV', 'development')}")
    
    # LangGraph API 상태 확인
    langgraph_available = await check_langgraph_api()
    if langgraph_available:
        logger.info("LangGraph API is available and responding")
    else:
        logger.warning("LangGraph API is not available, some features may not work properly")
    
    logger.info("Application startup complete")

# 루트 엔드포인트 추가
@app.get("/")
async def root():
    """기본 정보를 반환하는 루트 엔드포인트"""
    return {
        "app": "Chat Backend API",
        "version": "1.0.0",
        "description": "LangChain + FastAPI Chat Backend for LangGraph",
        "endpoints": {
            "health": "/api/health",
            "graph": "/graph/",
            "chat": "/api/chat/completions",
            "models": "/api/chat/models"
        }
    }

# LangGraph 워크플로우 정보 엔드포인트 추가
@app.get("/graph/")
async def graph_info():
    """LangGraph 워크플로우 정보를 반환합니다"""
    from app.routers.chat import chat_workflow
    
    return {
        "status": "active",
        "workflow_type": "chat",
        "entry_point": "process",
        "nodes": ["process"],
        "timestamp": datetime.now().isoformat()
    }

@app.get("/api/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    # LangGraph API 상태 확인
    langgraph_status = await check_langgraph_api()
    
    return {
        "status": "ok", 
        "message": "Server is running",
        "langgraph_api": "connected" if langgraph_status else "disconnected"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=os.getenv("APP_HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8080")),  # Railway 표준 PORT 환경 변수 사용, 기본값 8080
        reload=os.getenv("APP_ENV") == "development"
    )
