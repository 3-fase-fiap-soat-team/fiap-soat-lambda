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

    const response = await fetch("http://ade6621a32ddf48fca0265fba9f0d4e8-959184e9a1d3d4fa.elb.us-east-1.amazonaws.com/customers", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name,
        email,
        cpf
      })
    });

    if (!response.ok) {
      throw new Error(`Erro ao chamar a API: ${response.status}`);
    }

    const user = await response.json();

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

    const token = jwt.sign({ cpf, name, email }, process.env.JWT_SECRET!, { expiresIn: "1h" });

    return { statusCode: 200, body: JSON.stringify({ message: "Usuário criado", token, user }) };

  } catch (err: any) {
    console.error(err);
    return { statusCode: 400, body: JSON.stringify({ error: err.message }) };
  }
};
