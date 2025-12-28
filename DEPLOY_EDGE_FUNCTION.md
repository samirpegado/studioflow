# 🚀 Deploy da Edge Function - register-client

## Pré-requisitos

1. Instalar Supabase CLI:
```bash
npm install -g supabase
```

2. Fazer login no Supabase:
```bash
supabase login
```

3. Linkar o projeto:
```bash
supabase link --project-ref natibzklnyngnnegfrgo
```

## Deploy

Para fazer o deploy da Edge Function:

```bash
supabase functions deploy register-client
```

## Teste Local (Opcional)

Para testar localmente antes do deploy:

```bash
# Iniciar Supabase localmente
supabase start

# Deploy local
supabase functions serve register-client
```

## Verificação

Após o deploy, você pode testar a função através do dashboard do Supabase ou diretamente do app Flutter.

## Variáveis de Ambiente

A função usa automaticamente as variáveis de ambiente do projeto Supabase:
- `SUPABASE_URL`: URL do projeto (já configurado)
- `SUPABASE_SERVICE_ROLE_KEY`: Chave de serviço (já configurado)

## Estrutura

```
supabase/
└── functions/
    └── register-client/
        ├── index.ts          # Código da função
        └── README.md         # Documentação
```

## Endpoint

Após o deploy, a função estará disponível em:
```
https://natibzklnyngnnegfrgo.supabase.co/functions/v1/register-client
```

