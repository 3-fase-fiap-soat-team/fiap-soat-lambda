import { handler } from "./index";

const event = {
  body: JSON.stringify({
    cpf: "12345678923",
    name: "Bruno Mars",
    email: "brunomars@email.com"
  })
};

handler(event).then(response => {
  console.log("Resposta:", response);
}).catch(err => {
  console.error("Erro:", err);
});