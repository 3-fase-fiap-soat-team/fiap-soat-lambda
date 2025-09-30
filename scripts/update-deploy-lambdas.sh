#!/bin/bash

set -e

# Caminhos das Lambdas
SIGNUP_LAMBDA="fastfood-signup-lambda"
AUTH_LAMBDA="fastfood-auth-lambda"

# Nomes das funções na AWS
SIGNUP_FUNCTION="fastfoodSignup"
AUTH_FUNCTION="fastfoodAuth"

echo "=== Deploy Signup Lambda ==="
cd $SIGNUP_LAMBDA
echo "Instalando dependências..."
npm install
echo "Build do TypeScript..."
npm run build
echo "Criando zip..."
zip -r signup.zip dist node_modules package.json
echo "Atualizando Lambda na AWS..."
aws lambda update-function-code \
  --function-name $SIGNUP_FUNCTION \
  --zip-file fileb://signup.zip
echo "Signup Lambda atualizada com sucesso!"
cd ..

echo "=== Deploy Auth Lambda ==="
cd $AUTH_LAMBDA
echo "Instalando dependências..."
npm install
echo "Build do TypeScript..."
npm run build
echo "Criando zip..."
zip -r auth.zip dist node_modules package.json
echo "Atualizando Lambda na AWS..."
aws lambda update-function-code \
  --function-name $AUTH_FUNCTION \
  --zip-file fileb://auth.zip
echo "Auth Lambda atualizada com sucesso!"
cd ..

echo "=== Deploy finalizado ==="
