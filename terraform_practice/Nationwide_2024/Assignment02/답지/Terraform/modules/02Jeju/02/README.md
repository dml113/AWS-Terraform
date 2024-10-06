# terraform 사용 방법 # 
1) terraform apply 
2) 생성되있는 instance의 SSM "접속 -> 나가기" 반복 후 /cg/ssm/logs loggroup에 log가 올라오는 것을 기다리기
3) Cloudwatch dashboard create -> name은 cg-dashboard로 생성
4) 데이터 소스 유형은 Cloudwatch -> 데이터 유형은 지표 -> 위젯 유형은 Line으로 설정
5) 지표에서 cg-metric 선택 후 생성되있는 지표로 위젯 생성
6) 생성 후 cg-metric 편집 클릭
7) 그래프로 표시된 지표에 들어가 레이블 이름을 SSM Access: ${LAST}으로 지정 후 통계에 평균 1분으로 설정 
8) 옵션에서 밑에 있는 가로 주석 추가 클릭 -> 색은 연한 주황색으로 설정 후 레이블 이름은 Warning으로 설정 -> 값은 10 -> Fill은 above로 설정 후 위젯 업데이트
9) 위젯 이름을 cg-metric을 SSM Access Count로 변경
10) 오른쪽 위 +버튼 클릭 -> 데이터 소스 유형은 Cloudwatch -> 데이터 유형은 로그 선택 -> 로그 테이블 설정
11) 로그 그룹은 /cg/ssm/logs로 설정 
12) query 문에 아래 코드 넣고 생성
======================================================================================================================================================
fields  eventTime, eventSource, requestParameters.state as state, userIdentity.accountId as accountId, requestParameters.filters.1.value as sessionId
| filter eventSource = "ssm.amazonaws.com"
| filter eventName = "DescribeSessions"
| filter requestParameters.state = "Active"
| sort eventTime desc
| limit 20
======================================================================================================================================================
13) 그 후 생성한 위젯의 이름을 SSM Access Logs로 설정 