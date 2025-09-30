import 'dotenv/config';
import { CognitoIdentityProviderClient, AdminCreateUserCommand } from "@aws-sdk/client-cognito-identity-provider";
import jwt from "jsonwebtoken";

const client = new CognitoIdentityProviderClient({ region: "us-east-1" });

export const handler = async (event: any) => {

  try {
    const { cpf, name, email } = JSON.parse(event.body || "{}");

    if (!cpf || !name || !email) {
      return { statusCode: 400, body: JSON.stringify({ error: "cpf, name e email são obrigatórios" }) };
    }

    // Criar usuário no Cognito
    await client.send(new AdminCreateUserCommand({
      UserPoolId: process.env.USER_POOL_ID!,
      Username: cpf,
      UserAttributes: [
        { Name: "custom:cpf", Value: cpf },
        { Name: "name", Value: name },
        { Name: "email", Value: email }
      ],
      MessageAction: "SUPPRESS"
    }));

    // Gerar token JWT
    const token = jwt.sign({ cpf, name, email }, process.env.JWT_SECRET!, { expiresIn: "1h" });

    return { statusCode: 200, body: JSON.stringify({ message: "Usuário criado", token }) };

  } catch (err: any) {
    console.error(err);
    return { statusCode: 400, body: JSON.stringify({ error: err.message }) };
  }
};
