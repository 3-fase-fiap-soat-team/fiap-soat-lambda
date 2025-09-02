# FIAP SOAT - Lambda Autenticação

AWS Lambda para autenticação via CPF - Fase 3

## 🎯 **Objetivo**
Implementar função serverless para autenticar clientes via CPF, integrada com sistema de autenticação JWT/Cognito.

## 👨‍💻 **Responsável**
- **Dev 1 (MathLuchiari)** - Database + Lambda
- **Repositórios:** `fiap-soat-database-terraform` + `fiap-soat-lambda`
- **Foco:** RDS PostgreSQL + Autenticação via CPF
- **Tecnologias:** Terraform, AWS Lambda, RDS, Node.js/TypeScript

## 📁 **Estrutura do Projeto**
```
src/
├── auth/              # Handlers de autenticação
│   ├── handlers/      # Lambda handlers
│   ├── models/        # Modelos de dados
│   └── services/      # Lógica de negócio
├── shared/            # Utilitários compartilhados
│   ├── utils/         # Funções auxiliares
│   └── validators/    # Validadores CPF/JWT
tests/
├── unit/              # Testes unitários
└── integration/       # Testes de integração
infrastructure/        # Configuração SAM/CloudFormation
```

## ⚙️ **Configuração AWS Academy**
- **Região:** us-east-1
- **Budget:** $50 USD (AWS Academy)
- **Secrets:** Configurados na organização GitHub
- **Terraform State:** S3 + DynamoDB locks

## 🚀 **Setup Local**
```bash
# Clonar repositório
git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda.git
cd fiap-soat-lambda

# Configurar Git
git config user.name "MathLuchiari"
git config user.email "seu-email@gmail.com"

# Instalar dependências
npm install

# Configurar AWS CLI (se necessário)
aws configure set region us-east-1

# Executar testes
npm run test
npm run lint
```

## 🏗️ **Desenvolvimento**
```bash
# Executar testes
npm run test

# Build local
npm run build

# Deploy com SAM
sam build
sam deploy --guided  # Primeira vez
sam deploy           # Próximas vezes
```

## 🔐 **Secrets GitHub (Auto-configurados)**
- `AWS_ACCESS_KEY_ID` - Chave de acesso AWS Academy
- `AWS_SECRET_ACCESS_KEY` - Secret de acesso AWS Academy  
- `AWS_SESSION_TOKEN` - Token de sessão AWS Academy
- `AWS_REGION` - us-east-1
- `TF_STATE_BUCKET` - Bucket S3 para Terraform state
- `TF_STATE_LOCK_TABLE` - Tabela DynamoDB para locks

## 📋 **Requisitos da Fase 3**
- ✅ Function serverless para autenticar cliente via CPF
- ✅ Integração com sistema de autenticação (JWT/Cognito)
- ✅ Cliente se identifica APENAS com CPF (sem senha)
- ✅ Fluxo de integração usando JWT
- ✅ Deploy automatizado via GitHub Actions

## 🔄 **Workflow de Desenvolvimento**
1. **Branch:** `feature/[nome-da-feature]`
2. **Desenvolvimento:** Implementar + testes
3. **PR:** Solicitar review do team
4. **CI/CD:** GitHub Actions executa testes
5. **Deploy:** Automático após merge na main

## 🧪 **CI/CD Pipeline**
- **Trigger:** Push na `main` ou `develop`
- **Testes:** Jest + ESLint
- **Deploy:** SAM para AWS Academy
- **Notificação:** Slack/Teams (opcional)

## 📚 **Links Importantes**
- **Organização:** https://github.com/3-fase-fiap-soat-team
- **Secrets:** https://github.com/orgs/3-fase-fiap-soat-team/settings/secrets/actions
- **Database Repo:** https://github.com/3-fase-fiap-soat-team/fiap-soat-database-terraform
- **Planning:** [PLANO_TRABALHO_FASE3.md](../PLANO_TRABALHO_FASE3.md)

## ⚠️ **Importante - AWS Academy**
- **Budget limitado:** $50 USD total
- **Credenciais temporárias:** Renovar quando expirar
- **Monitorar custos:** AWS Cost Explorer
- **Recursos mínimos:** Usar apenas o necessário
