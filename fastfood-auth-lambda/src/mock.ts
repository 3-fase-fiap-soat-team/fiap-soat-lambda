import { handler } from "./index";

const event = {
  body: JSON.stringify({ cpf: "12345678923" })
};

handler(event).then(response => console.log(response)).catch(err => console.error(err));
