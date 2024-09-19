resource "aws_cloudwatch_log_group" "customer" {
  provider = aws.ap
  name              = "/wsi/webapp/customer"  # 원하는 로그 그룹 이름을 설정합니다.
  retention_in_days = 1  # 로그 보관 기간을 1일로 설정합니다.
}

resource "aws_cloudwatch_log_group" "product" {
  provider = aws.ap
  name              = "/wsi/webapp/product"  # 원하는 로그 그룹 이름을 설정합니다.
  retention_in_days = 1  # 로그 보관 기간을 1일로 설정합니다.
}

resource "aws_cloudwatch_log_group" "order" {
  provider = aws.ap
  name              = "/wsi/webapp/order"  # 원하는 로그 그룹 이름을 설정합니다.
  retention_in_days = 1  # 로그 보관 기간을 1일로 설정합니다.
}