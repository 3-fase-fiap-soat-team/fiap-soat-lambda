terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "api_name" {
  description = "Nome da API Gateway"
  type        = string
  default     = "fastfood-api"
}

variable "stage_name" {
  description = "Nome do stage da API"
  type        = string
  default     = "dev"
}

variable "signup_lambda_function_name" {
  description = "Nome da função Lambda de signup"
  type        = string
  default     = "fastfoodSignup"
}

variable "auth_lambda_function_name" {
  description = "Nome da função Lambda de auth"
  type        = string
  default     = "fastfoodAuth"
}

data "aws_lambda_function" "signup" {
  function_name = var.signup_lambda_function_name
}

data "aws_lambda_function" "auth" {
  function_name = var.auth_lambda_function_name
}

resource "aws_api_gateway_rest_api" "fastfood_api" {
  name        = var.api_name
  description = "API Gateway"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  parent_id   = aws_api_gateway_rest_api.fastfood_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_resource" "signup" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  parent_id   = aws_api_gateway_rest_api.fastfood_api.root_resource_id
  path_part   = "signup"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  parent_id   = aws_api_gateway_rest_api.fastfood_api.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "signup_post" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "signup_options" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.signup.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_options" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = data.aws_lambda_function.signup.invoke_arn
}

resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = data.aws_lambda_function.auth.invoke_arn
}

resource "aws_api_gateway_integration" "signup_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "auth_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "signup_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "auth_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "signup_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup_options.http_method
  status_code = aws_api_gateway_method_response.signup_cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "auth_cors" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_options.http_method
  status_code = aws_api_gateway_method_response.auth_cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_lambda_permission" "signup_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.signup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fastfood_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "auth_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fastfood_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "fastfood_deployment" {
  depends_on = [
    aws_api_gateway_integration.signup_lambda,
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.signup_cors,
    aws_api_gateway_integration.auth_cors,
  ]

  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  stage_name  = var.stage_name
}

output "api_gateway_url" {
  description = "URL da API Gateway"
  value       = "https://${aws_api_gateway_rest_api.fastfood_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "api_gateway_id" {
  description = "ID da API Gateway"
  value       = aws_api_gateway_rest_api.fastfood_api.id
}

output "signup_endpoint" {
  description = "Endpoint para signup"
  value       = "https://${aws_api_gateway_rest_api.fastfood_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}/signup"
}

output "auth_endpoint" {
  description = "Endpoint para auth"
  value       = "https://${aws_api_gateway_rest_api.fastfood_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}/auth"
}

data "aws_region" "current" {}
