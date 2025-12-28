# 🎵 StudioFlow
## Sistema de Agendamentos de Ensaios Musicais

---

## 📌 Visão Geral
O **StudioFlow** é um sistema de agendamento de ensaios e gravações para estúdios musicais, operando como SaaS multi-tenant.

**Tecnologias:**
- Frontend: Flutter
- Backend: Supabase
- Notificações: Brevo

---

## 👥 Tipos de Usuário
- **admin**: proprietário da plataforma
- **studio**: estúdios de ensaio/gravação
- **client**: músicos ou bandas

---

## 🔐 Regras de Cadastro

### 🏢 Studio
Cadastro realizado somente pelo admin.

Campos obrigatórios:
- nome_estudio
- cnpj
- telefone
- email
- endereco_cep
- endereco_rua
- endereco_cidade
- endereco_uf
- endereco_bairro
- responsavel_nome
- responsavel_cpf
- responsavel_telefone
- geolocalizacao

Login: email + senha

### 🎸 Client
Cadastro livre via aplicativo.

Campos obrigatórios:
- nome
- email
- telefone
- cpf_cnpj
- endereco_cep
- endereco_rua
- endereco_cidade
- endereco_uf
- endereco_bairro
- tipo (musico | banda)
- geolocalizacao

---

## 🎛 Funcionalidades Studio

### Gestão de Salas
Cada estúdio pode cadastrar uma ou mais salas.
Campos:
- nome_sala
- descricao
- valor_hora

### Configuração de Agenda
Definição de horários de funcionamento e bloqueios.

### Agendamento
Clientes solicitam ensaio → estúdio aprova → notificação + e-mail.

### Cancelamento
Estúdio pode cancelar a qualquer momento.

### Finalização
Estúdio informa valor recebido e forma de pagamento.

### Relatórios
Diário, mensal e anual.

---

## 🧑‍🎤 Funcionalidades Client

- Buscar estúdios por proximidade ou cidade
- Visualizar salas, horários e avaliações
- Solicitar e cancelar agendamentos
- Avaliar estúdios
- Consultar histórico

---

## 🧠 Regras de Negócio

- Estúdio criado apenas pelo admin
- Multi-tenant
- Sala obrigatória
- Cancelamento cliente até 24h antes
- Avaliação após ensaio finalizado
- Relatórios apenas com ensaios finalizados

