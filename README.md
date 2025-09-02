# FIAP SOAT - Lambda Autenticação

AWS Lambda para autenticação via CPF - Fase 3

## Estrutura
- `src/auth/` - Handlers de autenticação
- `src/shared/` - Utilitários compartilhados
- `tests/` - Testes unitários e integração
- `infrastructure/` - Configuração SAM/CloudFormation

## Desenvolvimento
```bash
npm install
npm run test
npm run build
sam build
sam deploy
```

## Responsável
- **Dev 1 (MathLuchiari)** - Database + Lambda
