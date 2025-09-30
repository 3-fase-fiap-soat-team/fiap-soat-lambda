#!/bin/bash

# Script para configurar credenciais AWS Academy rapidamente
# Uso: ./scripts/aws-config.sh

echo "=== Configuração de Credenciais AWS Academy ==="
echo

echo "Cole o conteúdo completo das credenciais AWS Academy:"
echo "(Pressione Ctrl+D quando terminar de colar)"
echo

# Ler todo o input até EOF
credentials_content=$(cat)

# Extrair valores usando grep e cut
aws_access_key_id=$(echo "$credentials_content" | grep "aws_access_key_id" | cut -d'=' -f2)
aws_secret_access_key=$(echo "$credentials_content" | grep "aws_secret_access_key" | cut -d'=' -f2)
aws_session_token=$(echo "$credentials_content" | grep "aws_session_token" | cut -d'=' -f2)

if [[ -n "$aws_access_key_id" && -n "$aws_secret_access_key" && -n "$aws_session_token" ]]; then
    echo "✅ Credenciais extraídas com sucesso!"
    echo "Configurando AWS CLI..."
    
    aws configure set aws_access_key_id "$aws_access_key_id"
    aws configure set aws_secret_access_key "$aws_secret_access_key"
    aws configure set aws_session_token "$aws_session_token"
    aws configure set region "us-east-1"
    aws configure set output json
    
    echo "✅ Credenciais configuradas!"
    echo
    
    # Testar conexão
    echo "🧪 Testando conexão com AWS..."
    if aws sts get-caller-identity > /dev/null 2>&1; then
        echo "✅ Conexão com AWS estabelecida com sucesso!"
        echo
        aws sts get-caller-identity
    else
        echo "❌ Erro ao conectar com AWS. Verifique as credenciais."
        exit 1
    fi
else
    echo "❌ Não foi possível extrair as credenciais."
    echo "Verifique se você colou o formato correto do AWS Academy:"
    echo "aws_access_key_id=..."
    echo "aws_secret_access_key=..."
    echo "aws_session_token=..."
    exit 1
fi