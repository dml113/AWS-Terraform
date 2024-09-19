# README.md

Terraform apply 종료 후 아래 작업을 실시 해줍니다.

ap-northeast-2 Region에 생성된 cg-bastion Session Manager 접근을 3번 반복합니다.

Cloudwatch Dashboard Create     : Name=cg-dashboard                     -> Autosavoe=On

Create Wideget                  : DataType=Metrics                      -> WidgetType=Line

Setting Metrics                 : WidgetName=SSM Access Count           -> Metrics=cg-metric

Setting Wideget                 : Label=SSM Access: ${LAST}             -> Statistic=Sum        -> Period=1m

Options Wideget                 : HorizontalAnnotations|Thresholds=Add  -> Label=Warning        -> Value=10     -> Fill=above

++ Create Wideget                : DataType=Logs                         -> WidgetType=Logs table

++ Logs Insights                 : LogGroup=/cg/ssm/logs                 -> QueryFilter=<아래참고>

```
++++++++++++++++++++++++++++++++++++++++++++++++++++     QueryFilter     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fields  eventTime, eventSource, requestParameters.state as state, userIdentity.accountId as accountId, requestParameters.filters.1.value as sessionId
| filter eventSource = "ssm.amazonaws.com"
| filter eventName = "DescribeSessions"
| filter requestParameters.state = "Active"
| sort eventTime desc
| limit 20
```
+++ Setting Wideget               : Name=SSM Access Logs
