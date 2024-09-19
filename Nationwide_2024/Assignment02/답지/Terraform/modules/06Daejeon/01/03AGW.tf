resource "aws_api_gateway_rest_api" "api" {
  name = "wsi-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration_response.post_integration_response_user,
    aws_api_gateway_integration_response.get_integration_response_user,
    aws_api_gateway_integration_response.delete_integration_response_user,
    aws_api_gateway_integration_response.integration_response_healthz
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}