from fastapi import APIRouter, HTTPException, status
from typing import List
from pydantic import BaseModel
import logging
from datetime import datetime
from langgraph.graph import StateGraph, END
from typing import TypedDict, Dict, Any

router = APIRouter()
logger = logging.getLogger(__name__)

# LangGraph 상태 정의
class GraphState(TypedDict):
    messages: List[Dict[str, Any]]

# LangGraph 그래프 생성
def create_chat_workflow():
    workflow = StateGraph(GraphState)
    
    def process_message(state: GraphState) -> GraphState:
        # 여기에 실제 챗봇 로직 구현
        last_message = state["messages"][-1]
        response = {
            "role": "assistant",
            "content": f"안녕하세요! '{last_message['content']}'에 대한 답변입니다."
        }
        state["messages"].append(response)
        return state
    
    workflow.add_node("process", process_message)
    workflow.set_entry_point("process")
    workflow.add_edge("process", END)
    
    return workflow.compile()

# 컴파일된 워크플로우
chat_workflow = create_chat_workflow()

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[Message]
    stream: bool = False

@router.post("/completions")
async def chat_completion(request: ChatRequest):
    """채팅 완성 요청을 처리합니다."""
    try:
        start_time = datetime.now()
        logger.info(f"Processing chat completion request with {len(request.messages)} messages")
        
        # LangGraph 실행
        result = chat_workflow.invoke({
            "messages": [msg.dict() for msg in request.messages]
        })
        
        # 응답 생성
        response = {
            "id": "chatcmpl-123",
            "object": "chat.completion",
            "created": int(datetime.now().timestamp()),
            "model": "gpt-4",
            "choices": [{
                "index": 0,
                "message": result["messages"][-1],  # 마지막 응답 메시지
                "finish_reason": "stop"
            }]
        }
        
        # 성공 로깅
        processing_time = (datetime.now() - start_time).total_seconds()
        logger.info(f"Successfully processed chat completion in {processing_time:.2f} seconds")
        
        return response
        
    except Exception as e:
        logger.error(f"Error in chat completion: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="채팅 처리 중 오류가 발생했습니다. 나중에 다시 시도해주세요."
        )

@router.get("/models")
async def list_models():
    """사용 가능한 모델 목록을 반환합니다."""
    return {
        "data": [
            {"id": "gpt-4", "object": "model", "created": 1686935002, "owned_by": "openai"},
            {"id": "gpt-3.5-turbo", "object": "model", "created": 1677610602, "owned_by": "openai"}
        ]
    }