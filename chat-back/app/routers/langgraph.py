from fastapi import APIRouter, Request, HTTPException, Depends, Header
from fastapi.responses import StreamingResponse
import httpx
import os
from typing import Optional, Dict, Any, List
from pydantic import BaseModel
import json
import logging
from dotenv import load_dotenv

# 로거 설정
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter()

# 환경 변수 가져오기
LANGGRAPH_API_URL = os.getenv("LANGGRAPH_API_URL")
LANGSMITH_API_KEY = os.getenv("LANGSMITH_API_KEY")

# httpx 클라이언트 생성
client = httpx.AsyncClient(timeout=60.0)

# 요청 헤더 설정 함수
def get_headers(authorization: Optional[str] = Header(None)):
    headers = {}
    
    # LangSmith API 키 추가
    if LANGSMITH_API_KEY:
        headers["x-api-key"] = LANGSMITH_API_KEY
    
    # 클라이언트에서 전달된 인증 헤더 추가
    if authorization:
        headers["Authorization"] = authorization
    
    return headers

# 환경 변수 검증
@router.get("/config")
async def get_config():
    """LangGraph 연결 설정 정보를 반환합니다."""
    if not LANGGRAPH_API_URL:
        return {"error": "LANGGRAPH_API_URL is not set"}
    
    return {
        "langgraph_url": LANGGRAPH_API_URL,
        "has_api_key": bool(LANGSMITH_API_KEY)
    }

# LangGraph API로 요청 전달 (스트리밍)
@router.get("/{assistant_id}/stream")
async def stream_endpoint(
    request: Request,
    assistant_id: str,
    headers: Dict[str, str] = Depends(get_headers)
):
    """LangGraph 서버로부터 스트리밍 응답을 전달합니다."""
    # 쿼리 파라미터 가져오기
    query_params = dict(request.query_params)
    
    # LangGraph API URL 구성
    url = f"{LANGGRAPH_API_URL}/{assistant_id}/stream"
    if query_params:
        query_string = "&".join([f"{k}={v}" for k, v in query_params.items()])
        url = f"{url}?{query_string}"
    
    try:
        logger.debug(f"Streaming request to LangGraph API: {url}")
        # LangGraph API로 스트리밍 요청 전달
        response = await client.get(url, headers=headers)
        
        # 응답 스트리밍
        return StreamingResponse(
            response.aiter_bytes(),
            status_code=response.status_code,
            media_type=response.headers.get("content-type")
        )
    except httpx.HTTPError as e:
        logger.error(f"Error streaming from LangGraph API: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error connecting to LangGraph API: {str(e)}")

# 메시지 모델
class Message(BaseModel):
    content: Any
    additional_kwargs: Dict[str, Any] = {}
    type: str = "human"
    example: bool = False

# 스레드 모델
class Thread(BaseModel):
    messages: List[Message]
    thread_id: Optional[str] = None

# LangGraph API로 요청 전달 (POST)
@router.post("/{assistant_id}/thread")
async def thread_endpoint(
    thread: Thread,
    assistant_id: str,
    headers: Dict[str, str] = Depends(get_headers)
):
    """새 스레드를 생성하거나 기존 스레드에 메시지를 추가합니다."""
    try:
        # LangGraph API URL 구성
        url = f"{LANGGRAPH_API_URL}/{assistant_id}/thread"
        
        logger.debug(f"Sending thread request to LangGraph API: {url}")
        # LangGraph API로 요청 전달
        response = await client.post(
            url,
            headers=headers,
            json=thread.dict()
        )
        
        # 응답 반환
        return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Error in thread endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error connecting to LangGraph API: {str(e)}")

# 스레드 목록 가져오기
@router.get("/{assistant_id}/threads")
async def list_threads(
    assistant_id: str,
    headers: Dict[str, str] = Depends(get_headers)
):
    """사용 가능한 스레드 목록을 반환합니다."""
    try:
        # LangGraph API URL 구성
        url = f"{LANGGRAPH_API_URL}/{assistant_id}/threads"
        
        logger.debug(f"Fetching threads from LangGraph API: {url}")
        # LangGraph API로 요청 전달
        response = await client.get(url, headers=headers)
        
        # 응답 반환
        return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Error listing threads: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error connecting to LangGraph API: {str(e)}")

# 스레드 가져오기
@router.get("/{assistant_id}/thread/{thread_id}")
async def get_thread(
    assistant_id: str,
    thread_id: str,
    headers: Dict[str, str] = Depends(get_headers)
):
    """특정 스레드의 정보를 반환합니다."""
    try:
        # LangGraph API URL 구성
        url = f"{LANGGRAPH_API_URL}/{assistant_id}/thread/{thread_id}"
        
        logger.debug(f"Fetching thread from LangGraph API: {url}")
        # LangGraph API로 요청 전달
        response = await client.get(url, headers=headers)
        
        # 응답 반환
        return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Error getting thread: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error connecting to LangGraph API: {str(e)}")

# 인터럽트 처리
@router.post("/{assistant_id}/interrupt/{run_id}")
async def interrupt_endpoint(
    request: Request,
    assistant_id: str,
    run_id: str,
    headers: Dict[str, str] = Depends(get_headers)
):
    """실행 중인 작업을 인터럽트하고 사용자 입력을 처리합니다."""
    try:
        # 요청 본문 가져오기
        body = await request.json()
        
        # LangGraph API URL 구성
        url = f"{LANGGRAPH_API_URL}/{assistant_id}/interrupt/{run_id}"
        
        logger.debug(f"Sending interrupt request to LangGraph API: {url}")
        # LangGraph API로 요청 전달
        response = await client.post(url, headers=headers, json=body)
        
        # 응답 반환
        return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Error in interrupt endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error connecting to LangGraph API: {str(e)}")
