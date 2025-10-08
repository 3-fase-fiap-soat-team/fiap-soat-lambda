# 🍔 Fastfood Serverless Auth

Este projeto contém a infraestrutura e o código das **Lambdas responsáveis pela autenticação de usuários** do sistema **Fastfood**, incluindo criação de contas e autenticação via **Amazon Cognito**.
A infraestrutura é provisionada automaticamente com **Terraform**, e o pipeline de **GitHub Actions** cuida de build, empacotamento, upload e deploy das funções Lambda.

---

## 📁 Estrutura do Projeto

```
.
├─ fastfood-signup-lambda/      # Lambda responsável por cadastro (signup)
├─ fastfood-auth-lambda/        # Lambda responsável por autenticação (auth/login)
├─ infrastructure/                   # Arquivos Terraform para provisionar a infraestrutura
│  ├─ main.tf
│  └─ terraform.tfvars
└─ .github/workflows/deploy.yml # Pipeline de CI/CD com GitHub Actions
```

---

## ☁️ Arquitetura da Solução

A aplicação é composta pelos seguintes recursos AWS:

* **Amazon Cognito User Pool** – Gerencia usuários, autenticação e atributos customizados (CPF, nome e email).
* **User Pool Client** – Interface para as Lambdas interagirem com o Cognito.
* **AWS Lambda - Signup** – Função para registrar novos usuários no Cognito.
* **AWS Lambda - Auth** – Função para autenticar usuários e gerar tokens JWT.
* **IAM Role para Lambda** – Permite que as funções se comuniquem com o Cognito.
* **Terraform** – Provisiona todos os recursos de forma declarativa.
* **GitHub Actions** – Automatiza build, upload e `terraform apply`.

---

## 🚀 Fluxo de Deploy Automatizado

1. **Push para a branch `main`** dispara o workflow.
2. O **GitHub Actions**:

   * Instala dependências e compila os projetos Lambda (TypeScript → JS).
3. **Terraform** é executado:

   * Cria/atualiza o Cognito User Pool e App Client.
   * Cria as funções Lambda com o código mais recente.
   * Configura variáveis de ambiente automaticamente.
4. Lambdas atualizadas são publicadas na AWS.

---

## 🛠️ Pré-requisitos

* Node.js 18+
* Terraform 1.5+
* AWS CLI configurado (caso rode localmente)

---

## 🔑 Variáveis de Ambiente das Lambdas

Cada Lambda utiliza as seguintes variáveis de ambiente:

| Variável       | Descrição                                      |
| -------------- | ---------------------------------------------- |
| `USER_POOL_ID` | ID do User Pool criado no Cognito              |
| `JWT_SECRET`   | Segredo usado para geração/validação de tokens |

> ⚠️ O `USER_POOL_ID` é preenchido automaticamente pelo Terraform no momento do deploy.

---

## 🧪 Testando as Funções

Você pode testar cada Lambda diretamente pelo **AWS Lambda Console** ou via **AWS CLI**.

### Signup (Cadastro)

```bash
aws lambda invoke \
  --function-name fastfoodSignup \
  --payload '{"name":"João","email":"joao@email.com","cpf":"12345678901"}' \
  response.json
cat response.json
```

### Auth (Login)

```bash
aws lambda invoke \
  --function-name fastfoodAuth \
  --payload '{"email":"joao@email.com","password":"minhasenha"}' \
  response.json
cat response.json
```

---

## 🧰 Comandos Úteis

### Inicializar Terraform (local)

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Remover toda a infraestrutura

```bash
terraform destroy
```

---

## 📦 Estrutura de Build (Lambda)

Cada função Lambda é compilada em JavaScript antes do empacotamento:

```bash
cd fastfood-signup-lambda
npm ci
npm run build
zip -r signup.zip dist/
```

> O mesmo processo se aplica à `fastfood-auth-lambda`.

---

## 📊 Outputs Importantes (Terraform)

Após o `terraform apply`, você verá:

| Output                | Descrição                      |
| --------------------- | ------------------------------ |
| `user_pool_id`        | ID do Cognito User Pool        |
| `app_client_id`       | ID do App Client Cognito       |
| `signup_lambda_arn`   | ARN da Lambda de cadastro      |
| `auth_lambda_arn`     | ARN da Lambda de autenticação  |
---

## 🧼 Limpeza do Ambiente

Para deletar tudo criado e validar o processo de criação do zero:

```bash
terraform destroy
```

Isso remove o User Pool, App Client, Lambdas e IAM Roles.

---

## 📚 Próximos Passos

* Integrar as Lambdas ao **API Gateway** para expor endpoints REST.
* Adicionar **Authorizer Cognito** para proteger rotas com JWT.
* Criar um frontend que consuma o fluxo de signup/login.

---

## 👨‍💻 Autor

**Fastfood Infra Team 🍔** – Infraestrutura serverless para autenticação escalável com AWS Lambda + Cognito + Terraform.
