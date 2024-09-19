resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role2"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "allow_ec2_and_logs"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = "*"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "function" {
  function_name = "security_group_monitor"
  filename      = "./files/06Daejeon/02/lambda_function.zip"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      LOG_GROUP_NAME  = aws_cloudwatch_log_group.log_group.name
      STREAM_NAME     = aws_cloudwatch_log_stream.streamA.name
      INSTANCE_ID     = aws_instance.instance.id
      SECURITY_GROUP_ID = aws_security_group.sg.id 
      CONFIG_RULE_NAME = "wsi-config-port"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.log_group.arn
}

resource "aws_lambda_permission" "allow_config_rule_execution" {
  statement_id  = "AllowConfigRuleExecution"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "config.amazonaws.com"
}