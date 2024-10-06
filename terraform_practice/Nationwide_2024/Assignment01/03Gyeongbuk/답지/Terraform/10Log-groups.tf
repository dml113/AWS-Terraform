resource "aws_cloudwatch_log_group" "customer" {
  name              = "/wsi/webapp/customer"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.log_goups_kms.arn
}

resource "aws_cloudwatch_log_group" "product" {
  name              = "/wsi/webapp/product"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.log_goups_kms.arn
}

resource "aws_cloudwatch_log_group" "order" {
  name              = "/wsi/webapp/order"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.log_goups_kms.arn
}