# API Gateway REST API 생성
resource "aws_api_gateway_rest_api" "serverless_api_gw" {
  name = "serverless-api-gw"
}

# Root 리소스 가져오기
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  path        = "/"
}

# 'user' 리소스 생성
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "user"
}

# POST 메서드 생성
resource "aws_api_gateway_method" "post_user" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "POST"
  authorization = "NONE"
}

# GET 메서드 생성
resource "aws_api_gateway_method" "get_user" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id   = aws_api_gateway_resource.user.id
  http_method   = "GET"
  authorization = "NONE"
}

# POST 메서드 통합
resource "aws_api_gateway_integration" "post_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.post_user.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:ap-northeast-2:dynamodb:action/PutItem"
  credentials             = aws_iam_role.APIGatewayDynamoDBRole.arn

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
#if($input.params('id').toLowerCase().contains('admin'))
  #set($context.responseOverride.status = 500)
  {
    "err": "contains an inappropriate name"
  }
#else
  {
    "TableName": "serverless-user-table",
    "Item": {
      "id": {"S": "$input.params('id')"},
      "age": {"S": "$input.params('age')"},
      "company": {"S": "$input.params('company')"}
    }
  }
#end
EOF
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

# POST 메서드 응답
resource "aws_api_gateway_method_response" "post_user_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.post_user.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "post_user_500" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.post_user.http_method
  status_code = "500"
}

# POST 통합 응답
resource "aws_api_gateway_integration_response" "post_user_integration_200" {
  rest_api_id         = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id         = aws_api_gateway_resource.user.id
  http_method         = aws_api_gateway_method.post_user.http_method
  status_code         = aws_api_gateway_method_response.post_user_200.status_code
  depends_on          = [aws_api_gateway_integration.post_user_integration]
  response_templates  = {
    "application/json" = <<EOF
  {
    "msg": "Success insert data"
  }
EOF
  }
}

resource "aws_api_gateway_integration_response" "post_user_integration_500" {
  rest_api_id         = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id         = aws_api_gateway_resource.user.id
  http_method         = aws_api_gateway_method.post_user.http_method
  status_code         = "500"
  selection_pattern   = "500"
  depends_on          = [aws_api_gateway_integration.post_user_integration]
  response_templates  = {
    "application/json" = <<EOF
{
  "err": "contains an inappropriate name"
}
EOF
  }
}



# GET 메서드 통합
resource "aws_api_gateway_integration" "get_user_integration" {
  rest_api_id             = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.get_user.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:ap-northeast-2:dynamodb:action/GetItem"
  credentials             = aws_iam_role.APIGatewayDynamoDBRole.arn

  request_templates = {
    "application/json" = <<EOF
{
  "TableName": "serverless-user-table",
  "Key": {
    "id": {
      "S": "$input.params('id')"
    }
  }
}
EOF
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

# GET 메서드 응답
resource "aws_api_gateway_method_response" "get_user_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.get_user.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "get_user_500" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.get_user.http_method
  status_code = "500"
}

# GET 통합 응답
resource "aws_api_gateway_integration_response" "get_user_integration_200_response" {
  rest_api_id         = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id         = aws_api_gateway_resource.user.id
  http_method         = aws_api_gateway_method.get_user.http_method
  status_code         = aws_api_gateway_method_response.get_user_200.status_code
  depends_on          = [aws_api_gateway_integration.get_user_integration]
  response_templates  = {
    "application/json" = <<EOF
{
  "id": "$input.path('$.Item.id.S')",
  "age": "$input.path('$.Item.age.S')",
  "company": "$input.path('$.Item.company.S')"
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "get_user_integration_500_response" {
  rest_api_id         = aws_api_gateway_rest_api.serverless_api_gw.id
  resource_id         = aws_api_gateway_resource.user.id
  http_method         = aws_api_gateway_method.get_user.http_method
  status_code         = aws_api_gateway_method_response.get_user_500.status_code
  selection_pattern   = "500"
  depends_on          = [aws_api_gateway_integration.get_user_integration]
  response_templates  = {
    "application/json" = "{}"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration_response.post_user_integration_200,
    aws_api_gateway_integration_response.post_user_integration_500,
    aws_api_gateway_integration_response.get_user_integration_200_response,
    aws_api_gateway_integration_response.get_user_integration_500_response
  ]
  rest_api_id = aws_api_gateway_rest_api.serverless_api_gw.id
  stage_name  = "v1"
}