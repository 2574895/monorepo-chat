// 프로덕션 환경에서는 API 키를 사용하지 않음
export function getApiKey(): string | null {
  return null;
}
