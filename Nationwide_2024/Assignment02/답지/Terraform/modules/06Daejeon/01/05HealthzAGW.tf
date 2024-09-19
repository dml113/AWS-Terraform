
resource "aws_api_gateway_resource" "resource_healthz" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "healthz"
}

resource "aws_api_gateway_method" "method_healthz" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_healthz.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_healthz" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_healthz.id
  http_method = aws_api_gateway_method.method_healthz.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "method_response_healthz" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource_healthz.id
  http_method = aws_api_gateway_method.method_healthz.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response_healthz" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.resource_healthz.id
  http_method  = aws_api_gateway_method.method_healthz.http_method
  status_code  = aws_api_gateway_method_response.method_response_healthz.status_code
  response_templates = {
    "application/json" = <<EOF
{
    "status": "ok"
}
EOF
  }
}