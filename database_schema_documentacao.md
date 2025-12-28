# 📊 StudioFlow - Documentação do Esquema de Banco de Dados

## 📋 Visão Geral

Este documento descreve o esquema completo do banco de dados do **StudioFlow**, um sistema SaaS multi-tenant para agendamento de ensaios musicais.

**Tecnologia:** PostgreSQL (Supabase)

**Especificidades do Supabase:**
- Usa `TEXT` ao invés de `VARCHAR` (recomendação do Supabase)
- Usa `NUMERIC` ao invés de `DECIMAL` para valores monetários
- Usa `gen_random_uuid()` para geração de UUIDs (já disponível por padrão)
- Usa `now()` para timestamps (ao invés de `CURRENT_TIMESTAMP`)
- Geolocalização armazenada como `latitude` e `longitude` (NUMERIC) ao invés de tipo POINT

---

## 🗂️ Estrutura do Banco de Dados

### 📌 Tabelas Principais

#### 1. **users**
Tabela central de autenticação e autorização.

**Campos:**
- `id` (UUID): Identificador único (gerado com `gen_random_uuid()`)
- `email` (TEXT): Email único do usuário
- `password_hash` (TEXT): Hash da senha
- `role` (ENUM): Tipo de usuário (`admin`, `studio`, `client`)
- `created_at`, `updated_at`, `deleted_at`: Timestamps (usando `now()`)

**Relacionamentos:**
- Um `user` pode ser um `studio` (1:1)
- Um `user` pode ser um `client` (1:1)

---

#### 2. **studios**
Estúdios musicais cadastrados exclusivamente pelo admin.

**Campos:**
- `id` (UUID): Identificador único (gerado com `gen_random_uuid()`)
- `user_id` (UUID): Referência ao usuário (FK)
- `nome_estudio` (TEXT): Nome do estúdio
- `cnpj` (TEXT): CNPJ único
- `telefone`, `email` (TEXT): Contatos
- `endereco_*` (TEXT): Dados de endereço completo
- `responsavel_*` (TEXT): Dados do responsável
- `latitude` (NUMERIC): Latitude em graus decimais (-90 a 90)
- `longitude` (NUMERIC): Longitude em graus decimais (-180 a 180)
- `ativo` (BOOLEAN): Status do estúdio

**Relacionamentos:**
- Pertence a um `user` (1:1)
- Possui várias `rooms` (1:N)
- Recebe vários `bookings` (1:N)
- Recebe várias `reviews` (1:N)

---

#### 3. **clients**
Clientes (músicos ou bandas) que se cadastram livremente.

**Campos:**
- `id` (UUID): Identificador único (gerado com `gen_random_uuid()`)
- `user_id` (UUID): Referência ao usuário (FK)
- `nome` (TEXT): Nome do cliente
- `email`, `telefone` (TEXT): Contatos
- `cpf_cnpj` (TEXT): CPF ou CNPJ
- `endereco_*` (TEXT): Dados de endereço completo
- `tipo` (ENUM): `musico` ou `banda`
- `latitude` (NUMERIC): Latitude em graus decimais (-90 a 90)
- `longitude` (NUMERIC): Longitude em graus decimais (-180 a 180)

**Relacionamentos:**
- Pertence a um `user` (1:1)
- Faz vários `bookings` (1:N)
- Escreve várias `reviews` (1:N)

---

#### 4. **rooms**
Salas dos estúdios para ensaios/gravações.

**Campos:**
- `id` (UUID): Identificador único (gerado com `gen_random_uuid()`)
- `studio_id` (UUID): Referência ao estúdio (FK)
- `nome_sala` (TEXT): Nome da sala
- `descricao` (TEXT): Descrição da sala
- `valor_hora` (NUMERIC): Preço por hora
- `ativo` (BOOLEAN): Status da sala

**Relacionamentos:**
- Pertence a um `studio` (N:1)
- Possui várias `schedule_configs` (1:N)
- Possui vários `schedule_blocks` (1:N)
- Recebe vários `bookings` (1:N)

---

#### 5. **schedule_configs**
Configuração de horários de funcionamento das salas.

**Campos:**
- `id` (UUID): Identificador único
- `room_id` (UUID): Referência à sala (FK)
- `day_of_week` (INTEGER): Dia da semana (0=Domingo, 6=Sábado)
- `start_time` (TIME): Horário de início
- `end_time` (TIME): Horário de fim
- `is_available` (BOOLEAN): Se está disponível neste dia

**Relacionamentos:**
- Pertence a uma `room` (N:1)

---

#### 6. **schedule_blocks**
Bloqueios de horários (feriados, manutenção, etc).

**Campos:**
- `id` (UUID): Identificador único
- `room_id` (UUID): Referência à sala (FK)
- `start_datetime` (TIMESTAMP): Início do bloqueio
- `end_datetime` (TIMESTAMP): Fim do bloqueio
- `motivo` (VARCHAR): Motivo do bloqueio

**Relacionamentos:**
- Pertence a uma `room` (N:1)

---

#### 7. **bookings**
Agendamentos de ensaios.

**Campos:**
- `id` (UUID): Identificador único
- `client_id` (UUID): Referência ao cliente (FK)
- `room_id` (UUID): Referência à sala (FK)
- `studio_id` (UUID): Referência ao estúdio (FK)
- `start_datetime` (TIMESTAMP): Início do agendamento
- `end_datetime` (TIMESTAMP): Fim do agendamento
- `status` (ENUM): `pending`, `approved`, `cancelled`, `completed`
- `valor_hora` (NUMERIC): Valor por hora no momento do agendamento
- `valor_total` (NUMERIC): Valor total calculado
- `valor_recebido` (NUMERIC): Valor efetivamente recebido
- `forma_pagamento` (ENUM): Método de pagamento
- `observacoes` (TEXT): Observações do agendamento
- `cancelled_at`, `cancelled_by`, `motivo_cancelamento`: Dados de cancelamento
- `completed_at` (TIMESTAMP): Data de finalização

**Relacionamentos:**
- Pertence a um `client` (N:1)
- Pertence a uma `room` (N:1)
- Pertence a um `studio` (N:1)
- Pode ter uma `review` (1:1)

**Regras de Negócio:**
- Cliente pode cancelar até 24h antes
- Estúdio pode cancelar a qualquer momento
- Valor recebido só é preenchido quando finalizado

---

#### 8. **reviews**
Avaliações dos estúdios pelos clientes.

**Campos:**
- `id` (UUID): Identificador único
- `booking_id` (UUID): Referência ao agendamento (FK, UNIQUE)
- `client_id` (UUID): Referência ao cliente (FK)
- `studio_id` (UUID): Referência ao estúdio (FK)
- `rating` (INTEGER): Nota de 1 a 5
- `comentario` (TEXT): Comentário da avaliação

**Relacionamentos:**
- Pertence a um `booking` (1:1)
- Pertence a um `client` (N:1)
- Pertence a um `studio` (N:1)

**Regras de Negócio:**
- Só pode avaliar após ensaio finalizado
- Uma avaliação por agendamento

---

#### 9. **notifications**
Notificações do sistema para integração com Brevo.

**Campos:**
- `id` (UUID): Identificador único
- `user_id` (UUID): Referência ao usuário (FK)
- `booking_id` (UUID): Referência ao agendamento (FK, opcional)
- `type` (VARCHAR): Tipo da notificação
- `title` (VARCHAR): Título
- `message` (TEXT): Mensagem
- `email_sent` (BOOLEAN): Se o email foi enviado
- `email_sent_at` (TIMESTAMP): Quando foi enviado
- `read_at` (TIMESTAMP): Quando foi lida

**Relacionamentos:**
- Pertence a um `user` (N:1)
- Pode estar relacionada a um `booking` (N:1)

---

## 🔧 Funcionalidades Implementadas

### ✅ Funções Úteis

1. **calculate_distance(lat1, lon1, lat2, lon2)**
   - Calcula distância entre dois pontos geográficos em km
   - Usa a fórmula de Haversine para cálculos precisos
   - Parâmetros: latitude e longitude de cada ponto (NUMERIC)
   - Retorna: distância em quilômetros (NUMERIC)

2. **is_time_slot_available(room_id, start_datetime, end_datetime)**
   - Verifica se um horário está disponível para agendamento
   - Considera:
     - Horários de funcionamento configurados
     - Bloqueios existentes
     - Agendamentos aprovados/completados

### 📊 Views para Relatórios

1. **v_daily_reports**
   - Relatórios diários por estúdio
   - Total de ensaios, clientes, receita e média de avaliações

2. **v_monthly_reports**
   - Relatórios mensais por estúdio
   - Mesmas métricas agrupadas por mês

3. **v_yearly_reports**
   - Relatórios anuais por estúdio
   - Mesmas métricas agrupadas por ano

4. **v_studios_with_ratings**
   - Estúdios com suas avaliações médias
   - Útil para busca e ranking

---

## 🔒 Segurança (RLS - Row Level Security)

O esquema inclui políticas básicas de Row Level Security para uso com Supabase:

- **Admin**: Pode ver todos os dados
- **Studio**: Pode ver apenas seus próprios dados e agendamentos de suas salas
- **Client**: Pode ver todos os estúdios (para busca) e apenas seus próprios agendamentos

**⚠️ Nota:** As políticas RLS devem ser ajustadas conforme os requisitos específicos de segurança do projeto.

---

## 📝 Enums Definidos

- **user_role**: `admin`, `studio`, `client`
- **client_type**: `musico`, `banda`
- **booking_status**: `pending`, `approved`, `cancelled`, `completed`
- **payment_method**: `dinheiro`, `pix`, `cartao_debito`, `cartao_credito`, `transferencia`

---

## 🔄 Triggers Automáticos

Todos os campos `updated_at` são atualizados automaticamente através de triggers quando um registro é modificado.

---

## 📍 Índices Criados

O esquema inclui índices otimizados para:
- Buscas por email, CPF/CNPJ
- Buscas geográficas (latitude/longitude)
- Filtros por status, datas
- Relacionamentos entre tabelas
- Soft deletes (deleted_at IS NULL)

---

## 🚀 Como Usar

1. Execute o arquivo `database_schema.sql` no seu banco PostgreSQL/Supabase
2. Ajuste as políticas RLS conforme necessário
3. Teste as funções e views criadas

**Nota:** O Supabase já possui UUID instalado por padrão, então não é necessário instalar extensões adicionais.

---

## 📌 Próximos Passos Sugeridos

1. Criar seeds iniciais (usuário admin padrão)
2. Implementar stored procedures para operações complexas
3. Adicionar mais validações de negócio via triggers
4. Criar índices adicionais baseados em queries reais
5. Implementar backup e estratégias de retenção de dados

