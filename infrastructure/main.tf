# FastFood FIAP SOAT - Infraestrutura Simplificada
# Lambdas + API Gateway (sem IAM personalizado)

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

# =============================================================================
# VARIÁVEIS
# =============================================================================

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

variable "lambda_runtime" {
  description = "Runtime das funções Lambda"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Timeout das funções Lambda em segundos"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memória das funções Lambda em MB"
  type        = number
  default     = 128
}

variable "user_pool_id" {
  description = "ID do User Pool do Cognito"
  type        = string
  default     = ""
}

variable "jwt_secret" {
  description = "Chave secreta para JWT"
  type        = string
  default     = "your-jwt-secret-here"
  sensitive   = true
}

# =============================================================================
# BUILD DAS LAMBDAS
# =============================================================================

resource "null_resource" "build_signup" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ../fastfood-signup-lambda
      npm install
      npm run build
    EOT
  }
}

resource "null_resource" "build_auth" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ../fastfood-auth-lambda
      npm install
      npm run build
    EOT
  }
}

# =============================================================================
# ARQUIVOS ZIP DAS LAMBDAS
# =============================================================================

data "archive_file" "signup_zip" {
  type        = "zip"
  source_dir  = "../fastfood-signup-lambda/dist"
  output_path = "../fastfood-signup-lambda/function.zip"
  depends_on  = [null_resource.build_signup]
}

data "archive_file" "auth_zip" {
  type        = "zip"
  source_dir  = "../fastfood-auth-lambda/dist"
  output_path = "../fastfood-auth-lambda/function.zip"
  depends_on  = [null_resource.build_auth]
}

# =============================================================================
# LAMBDAS (usando role existente)
# =============================================================================

resource "aws_lambda_function" "signup" {
  filename         = data.archive_file.signup_zip.output_path
  function_name    = "fastfoodSignup"
  role            = "arn:aws:iam::905418273969:role/LabRole"
  handler         = "dist/index.handler"
  source_code_hash = data.archive_file.signup_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USER_POOL_ID = var.user_pool_id
      JWT_SECRET   = var.jwt_secret
    }
  }

  depends_on = [
    data.archive_file.signup_zip
  ]
}

resource "aws_lambda_function" "auth" {
  filename         = data.archive_file.auth_zip.output_path
  function_name    = "fastfoodAuth"
  role            = "arn:aws:iam::905418273969:role/LabRole"
  handler         = "dist/index.handler"
  source_code_hash = data.archive_file.auth_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

  environment {
    variables = {
      USER_POOL_ID = var.user_pool_id
      JWT_SECRET   = var.jwt_secret
    }
  }

  depends_on = [
    data.archive_file.auth_zip
  ]
}

# =============================================================================
# API GATEWAY
# =============================================================================

resource "aws_api_gateway_rest_api" "fastfood_api" {
  name        = var.api_name
  description = "API Gateway para FastFood FIAP SOAT"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
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

# Métodos POST
resource "aws_api_gateway_method" "signup_post" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "NONE"
}

# Métodos OPTIONS (CORS)
resource "aws_api_gateway_method" "signup_options" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.signup.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "auth_options" {
  rest_api_id   = aws_api_gateway_rest_api.fastfood_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integrações Lambda
resource "aws_api_gateway_integration" "signup_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.signup.id
  http_method = aws_api_gateway_method.signup_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.signup.invoke_arn
}

resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id = aws_api_gateway_rest_api.fastfood_api.id
  resource_id = aws_api_gateway_resource.auth.id
  http_method = aws_api_gateway_method.auth_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.auth.invoke_arn
}

# Integrações CORS
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

# Responses CORS
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

# Permissões para API Gateway invocar as Lambdas
resource "aws_lambda_permission" "signup_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signup.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fastfood_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "auth_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.fastfood_api.execution_arn}/*/*"
}

# Deploy da API
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

# =============================================================================
# OUTPUTS
# =============================================================================

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

output "signup_lambda_arn" {
  description = "ARN da função Lambda de signup"
  value       = aws_lambda_function.signup.arn
}

output "auth_lambda_arn" {
  description = "ARN da função Lambda de auth"
  value       = aws_lambda_function.auth.arn
}

data "aws_region" "current" {}
