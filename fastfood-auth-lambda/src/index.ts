import 'dotenv/config';
import { CognitoIdentityProviderClient, AdminGetUserCommand } from "@aws-sdk/client-cognito-identity-provider";
import jwt from "jsonwebtoken";

const client = new CognitoIdentityProviderClient({ region: "us-east-1" });

export const handler = async (event: any) => {
  try {
    const { cpf } = JSON.parse(event.body || "{}");

    if (!cpf) return { statusCode: 400, body: JSON.stringify({ error: "cpf é obrigatório" }) };

    const user = await client.send(new AdminGetUserCommand({
      UserPoolId: process.env.USER_POOL_ID!,
      Username: cpf
    }));

    const attributes: Record<string, string> = {};
    user.UserAttributes?.forEach(attr => {
      if (attr.Name !== undefined && attr.Value !== undefined) {
        attributes[attr.Name] = attr.Value;
      }
    });

    const token = jwt.sign({
      cpf: attributes["custom:cpf"],
      name: attributes["name"],
      email: attributes["email"]
    }, process.env.JWT_SECRET!, { expiresIn: "1h" });

    return { statusCode: 200, body: JSON.stringify({ message: "Autenticação bem-sucedida", token }) };

  } catch (err: any) {
    console.error(err);
    return { statusCode: 400, body: JSON.stringify({ error: err.message }) };
  }
};
