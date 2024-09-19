# 주의 사항 # 
1. 경기 종료 전 채점을 위해 DynamoDB에 생성된 Item들은 모두 삭제하여 아무 item도 없는 DynamoDB Table로 만들어야 합니다. (미진행 시 채점 시 불이익이 발생할 수 있음)
2. API Gateway stage를 v1으로 직접 배포해준다.