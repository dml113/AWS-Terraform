resource "aws_api_gateway_resource" "resource_user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_method" "post_method_user" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_user.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_integration_user" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_user.id
  http_method             = aws_api_gateway_method.post_method_user.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.role.arn
  uri                     = "arn:aws:apigateway:ap-northeast-2:dynamodb:action/PutItem"
  request_templates = {
    "application/json" = <<EOF
{  
  "TableName": "wsi-table",
  "Item": {
    "name": {"S": $input.json('name')},
    "age": {"N": "$input.json('age')"},
    "country": {"S": $input.json('country')}
  }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "post_method_response_user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_user.id
  http_method = aws_api_gateway_method.post_method_user.http_method
  status_code = "200"
  depends_on = [
    aws_api_gateway_resource.resource_user
  ]
}

resource "aws_api_gateway_integration_response" "post_integration_response_user" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.resource_user.id
  http_method  = aws_api_gateway_method.post_method_user.http_method
  status_code  = aws_api_gateway_method_response.post_method_response_user.status_code
  response_templates = {
    "application/json" = <<EOF
{
    "msg": "Finished"
}
EOF
  }
  depends_on = [
    aws_api_gateway_resource.resource_user
  ]
}

resource "aws_api_gateway_method" "get_method_user" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_user.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration_user" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_user.id
  http_method             = aws_api_gateway_method.get_method_user.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.role.arn
  uri                     = "arn:aws:apigateway:ap-northeast-2:dynamodb:action/GetItem"
  request_templates = {
    "application/json" = <<EOF
{  
  "TableName": "wsi-table",
  "Key": {
    "name": {
      "S": "$input.params('name')"
    }
  }
}
EOF
  }
}


resource "aws_api_gateway_method_response" "get_method_response_user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_user.id
  http_method = aws_api_gateway_method.get_method_user.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "get_integration_response_user" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_user.id
  http_method = aws_api_gateway_method.get_method_user.http_method
  status_code  = aws_api_gateway_method_response.get_method_response_user.status_code
  response_templates = {
    "application/json" = <<EOF
{  
  "name": "$input.path('$.Item.name.S')",
  "age": $input.path('$.Item.age.N'),
  "country": "$input.path('$.Item.country.S')"
}
EOF
  }
}

resource "aws_api_gateway_method" "delete_method_user" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_user.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_integration_user" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_user.id
  http_method             = aws_api_gateway_method.delete_method_user.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.role.arn
  uri                     = "arn:aws:apigateway:ap-northeast-2:dynamodb:action/DeleteItem"
  request_templates = {
    "application/json" = <<EOF
{  
  "TableName": "wsi-table",
  "Key": {
    "name": {
      "S": "$input.params('name')"
    }
  }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "delete_method_response_user" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_user.id
  http_method = aws_api_gateway_method.delete_method_user.http_method
  status_code = "200"
  depends_on = [
    aws_api_gateway_resource.resource_user
  ]
}

resource "aws_api_gateway_integration_response" "delete_integration_response_user" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.resource_user.id
  http_method  = aws_api_gateway_method.delete_method_user.http_method
  status_code  = aws_api_gateway_method_response.delete_method_response_user.status_code
  response_templates = {
    "application/json" = <<EOF
{
    "msg": "Deleted"
}
EOF
  }
  depends_on = [
    aws_api_gateway_method_response.delete_method_response_user
  ]
}