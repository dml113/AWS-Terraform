# AWS Config 규칙 설정
resource "aws_config_config_rule" "wsi_config_port_rule" {
  name = "wsi-config-port"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.function.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  input_parameters = jsonencode({
    "allowedInboundPorts": [22, 80],
    "allowedOutboundPorts": [22, 80, 443]
  })

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  depends_on = [
    aws_lambda_permission.allow_config_rule_execution
  ]
}