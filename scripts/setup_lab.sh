#!/bin/bash
set -e

REGION="us-east-1"
POOL_NAME="fastfood-users"
SIGNUP_LAMBDA="fastfoodSignup"
AUTH_LAMBDA="fastfoodAuth"
JWT_SECRET="fiap2025grupo242"

ROLE_ARN="arn:aws:iam::471112819787:role/LabRole"
echo "Usando LabRole: $ROLE_ARN"

echo "=== Criando User Pool ==="
POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name $POOL_NAME \
    --schema '[
        {"Name":"cpf","AttributeDataType":"String","Mutable":false},
        {"Name":"name","AttributeDataType":"String","Required":true},
        {"Name":"email","AttributeDataType":"String","Required":true}
    ]' \
    --auto-verified-attributes email \
    --query 'UserPool.Id' --output text)
echo "User Pool criado: $POOL_ID"

echo "=== Criando App Client ==="
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id $POOL_ID \
    --client-name fastfood-client \
    --no-generate-secret \
    --query 'UserPoolClient.ClientId' --output text)
echo "App Client criado: $CLIENT_ID"

build_zip_lambda() {
  LAMBDA_PATH=$1
  ZIP_NAME=$2

  echo "Atualizando .env em $LAMBDA_PATH..."
  cat > $LAMBDA_PATH/.env <<EOL
USER_POOL_ID=$POOL_ID
JWT_SECRET=$JWT_SECRET
EOL

  echo "Instalando dependências e build em $LAMBDA_PATH..."
  cd $LAMBDA_PATH
  npm install
  npm run build
  zip -r ../$ZIP_NAME dist node_modules package.json
  cd ..
}

echo "=== Criando Lambda de Signup ==="
build_zip_lambda ./fastfood-signup-lambda signup.zip
aws lambda create-function \
  --function-name $SIGNUP_LAMBDA \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler dist/index.handler \
  --zip-file fileb://signup.zip \
  --environment Variables="{USER_POOL_ID=$POOL_ID,JWT_SECRET=$JWT_SECRET}"
echo "Lambda de Signup criada"

echo "=== Criando Lambda de Autenticação ==="
build_zip_lambda ./fastfood-auth-lambda auth.zip
aws lambda create-function \
  --function-name $AUTH_LAMBDA \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler dist/index.handler \
  --zip-file fileb://auth.zip \
  --environment Variables="{USER_POOL_ID=$POOL_ID,JWT_SECRET=$JWT_SECRET}"
echo "Lambda de Autenticação criada"

echo "=== Setup concluído ==="
echo "User Pool ID: $POOL_ID"
echo "App Client ID: $CLIENT_ID"
echo "Signup Lambda: $SIGNUP_LAMBDA"
echo "Auth Lambda: $AUTH_LAMBDA"
