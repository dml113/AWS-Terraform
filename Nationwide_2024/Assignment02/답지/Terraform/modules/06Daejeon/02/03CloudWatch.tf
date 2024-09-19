resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ec2/deny/port"
}

resource "aws_cloudwatch_log_stream" "streamA" {
  name           = "deny-${aws_instance.instance.id}"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}