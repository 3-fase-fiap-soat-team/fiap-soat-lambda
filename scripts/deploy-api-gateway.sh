#!/bin/bash

set -e


REGION="us-east-1"
TERRAFORM_DIR="infrastructure"

echo "=== Deploy API Gateway com Terraform ==="


if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Erro: AWS CLI não está configurado ou credenciais inválidas"
    echo "Execute: aws configure"
    exit 1
fi


if ! command -v terraform &> /dev/null; then
    echo "Erro: Terraform não está instalado"
    echo "Instale o Terraform: https://terraform.io/downloads"
    exit 1
fi


cd $TERRAFORM_DIR

echo "Inicializando Terraform..."
terraform init

echo "Validando configuração Terraform..."
terraform validate

echo "Planejando deploy..."
terraform plan -out=tfplan

echo "Aplicando configuração..."
terraform apply tfplan

echo "=== Deploy concluído! ==="


echo ""
echo "Informações da API Gateway:"
terraform output

    
cat > ../api-gateway-info.txt << EOF
API Gateway Information (Terraform)
===================================
$(terraform output -json | jq -r 'to_entries[] | "\(.key): \(.value.value)"')
EOF

echo ""
echo "Informações salvas em api-gateway-info.txt"
echo ""
echo "Para testar a API:"
echo "1. Signup: curl -X POST \$(terraform output -raw signup_endpoint) -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\",\"name\":\"João Silva\",\"email\":\"joao@email.com\"}'"
echo "2. Auth: curl -X POST \$(terraform output -raw auth_endpoint) -H 'Content-Type: application/json' -d '{\"cpf\":\"12345678901\"}'"

cd ..
