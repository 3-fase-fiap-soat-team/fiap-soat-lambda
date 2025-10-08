#!/bin/bash

set -e

REGION="us-east-1"
API_NAME="fastfood-api"
STAGE_NAME="dev"

SIGNUP_FUNCTION="fastfoodSignup"
AUTH_FUNCTION="fastfoodAuth"

# Buscar Account ID da conta AWS atual
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $ACCOUNT_ID"

echo "=== Criando API Gateway ==="


echo "Criando API Gateway REST API..."
API_ID=$(aws apigateway create-rest-api \
  --name $API_NAME \
  --description "API Gateway" \
  --region $REGION \
  --query 'id' \
  --output text)

echo "API Gateway criado com ID: $API_ID"


ROOT_RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query 'items[0].id' \
  --output text)

echo "Root Resource ID: $ROOT_RESOURCE_ID"


echo "Criando recursos..."


AUTH_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_RESOURCE_ID \
  --path-part "auth" \
  --region $REGION \
  --query 'id' \
  --output text)


SIGNUP_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_RESOURCE_ID \
  --path-part "signup" \
  --region $REGION \
  --query 'id' \
  --output text)

echo "Recursos criados - Auth: $AUTH_RESOURCE_ID, Signup: $SIGNUP_RESOURCE_ID"


SIGNUP_LAMBDA_ARN=$(aws lambda get-function \
  --function-name $SIGNUP_FUNCTION \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

AUTH_LAMBDA_ARN=$(aws lambda get-function \
  --function-name $AUTH_FUNCTION \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

echo "ARNs das Lambdas - Signup: $SIGNUP_LAMBDA_ARN, Auth: $AUTH_LAMBDA_ARN"


echo "Configurando permissões..."

# Remover permissões antigas se existirem
aws lambda remove-permission \
  --function-name $SIGNUP_FUNCTION \
  --statement-id "api-gateway-signup" \
  --region $REGION 2>/dev/null || true

aws lambda remove-permission \
  --function-name $AUTH_FUNCTION \
  --statement-id "api-gateway-auth" \
  --region $REGION 2>/dev/null || true

# Adicionar novas permissões
aws lambda add-permission \
  --function-name $SIGNUP_FUNCTION \
  --statement-id "api-gateway-signup" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*" \
  --region $REGION

aws lambda add-permission \
  --function-name $AUTH_FUNCTION \
  --statement-id "api-gateway-auth" \
  --action "lambda:InvokeFunction" \
  --principal "apigateway.amazonaws.com" \
  --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*" \
  --region $REGION


echo "Criando métodos POST..."


aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION


aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE \
  --region $REGION


echo "Configurando integrações Lambda..."


aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$SIGNUP_LAMBDA_ARN/invocations" \
  --region $REGION


aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$AUTH_LAMBDA_ARN/invocations" \
  --region $REGION


echo "Configurando CORS..."

# Criar método OPTIONS para Signup
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region $REGION

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false \
  --region $REGION

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
  --region $REGION

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $SIGNUP_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''","method.response.header.Access-Control-Allow-Methods": "'\''POST,OPTIONS'\''","method.response.header.Access-Control-Allow-Origin": "'\''*'\''"}' \
  --region $REGION

# Criar método OPTIONS para Auth
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE \
  --region $REGION

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false \
  --region $REGION

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
  --region $REGION

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $AUTH_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''","method.response.header.Access-Control-Allow-Methods": "'\''POST,OPTIONS'\''","method.response.header.Access-Control-Allow-Origin": "'\''*'\''"}' \
  --region $REGION


echo "Fazendo deploy da API..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name $STAGE_NAME \
  --region $REGION


API_URL="https://$API_ID.execute-api.$REGION.amazonaws.com/$STAGE_NAME"

echo "=== API Gateway criado com sucesso! ==="
echo "API ID: $API_ID"
echo "URL da API: $API_URL"
echo ""
echo "Endpoints disponíveis:"
echo "POST $API_URL/signup - Criar usuário"
echo "POST $API_URL/auth - Autenticar usuário"
echo ""
echo "Exemplo de uso:"
echo "curl -X POST $API_URL/signup -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\",\"name\":\"João Silva\",\"email\":\"joao@email.com\"}'"
echo "curl -X POST $API_URL/auth -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\"}'"


cat > api-gateway-info.txt << EOF
API Gateway Information
======================
API ID: $API_ID
API URL: $API_URL
Region: $REGION
Stage: $STAGE_NAME

Endpoints:
- POST $API_URL/signup - Criar usuário
- POST $API_URL/auth - Autenticar usuário

Lambda Functions:
- Signup: $SIGNUP_FUNCTION ($SIGNUP_LAMBDA_ARN)
- Auth: $AUTH_FUNCTION ($AUTH_LAMBDA_ARN)
EOF

echo "Informações salvas em api-gateway-info.txt"
