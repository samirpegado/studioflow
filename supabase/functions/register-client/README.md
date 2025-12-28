# Edge Function: register-client

Edge Function para registro de novos clientes no sistema StudioFlow.

## Funcionalidades

- Verifica se o email já existe em `public.users`
- Verifica se o CPF/CNPJ já existe em `public.clients`
- Cria usuário em `auth.users`
- Cria registro em `public.users`
- Cria registro em `public.clients`
- Retorna resposta padronizada com `success`, `message` e `notification`

## Request Body

```json
{
  "email": "usuario@example.com",
  "password": "senha123",
  "nome": "Nome do Cliente",
  "telefone": "84999999999",
  "cpf_cnpj": "12345678900",
  "endereco_cep": "59075420",
  "endereco_rua": "Rua Example",
  "endereco_cidade": "Natal",
  "endereco_uf": "RN",
  "endereco_bairro": "Bairro Example",
  "tipo": "musico",
  "latitude": 0.0,
  "longitude": 0.0
}
```

## Response

### Sucesso (201)

```json
{
  "success": true,
  "message": "Usuário cadastrado com sucesso",
  "notification": "Cadastro realizado com sucesso! Você já pode fazer login.",
  "data": {
    "userId": "uuid-do-usuario",
    "clientId": "uuid-do-cliente"
  }
}
```

### Erro (400, 409, 500)

```json
{
  "success": false,
  "message": "Mensagem técnica do erro",
  "notification": "Mensagem amigável para o usuário"
}
```

## Deploy

```bash
supabase functions deploy register-client
```

## Variáveis de Ambiente

A função usa automaticamente as variáveis de ambiente do Supabase:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

