resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "visitor_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_processor.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor_route" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "ANY /log"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "visitor_stage" {
    api_id = aws_apigatewayv2_api.visitor_api.id
    name = "$default"
    auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.visitor_processor.function_name
    principal = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}