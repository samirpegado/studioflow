# 🎵 StudioFlow

Sistema de Agendamentos de Ensaios Musicais - Flutter App

## 📋 Descrição

O **StudioFlow** é um sistema SaaS multi-tenant para agendamento de ensaios e gravações em estúdios musicais. O aplicativo foi desenvolvido em Flutter com design responsivo mobile-first, funcionando tanto em dispositivos móveis quanto na web.

## 🚀 Tecnologias

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL)
- **State Management**: Provider
- **Routing**: GoRouter
- **Notificações**: Brevo (a implementar)

## 📱 Funcionalidades

### Para Clientes (Músicos/Bandas)
- ✅ Cadastro livre via aplicativo
- ✅ Busca de estúdios por proximidade ou cidade
- ✅ Visualização de salas e avaliações
- ✅ Solicitação de agendamentos
- ✅ Cancelamento de agendamentos (até 24h antes)
- ✅ Histórico de agendamentos
- ✅ Avaliação de estúdios (após ensaio finalizado)

### Para Estúdios
- ✅ Dashboard com resumo de atividades
- ✅ Gestão de salas (criar, editar)
- ✅ Visualização e aprovação de agendamentos
- ✅ Finalização de ensaios com valor recebido
- ✅ Cancelamento de agendamentos
- ✅ Filtros por status de agendamento

## 🏗️ Estrutura do Projeto

```
lib/
├── core/
│   ├── config/          # Configurações (Supabase)
│   ├── constants/       # Constantes da aplicação
│   ├── models/          # Modelos de dados
│   ├── providers/       # Providers (State Management)
│   ├── services/        # Serviços (Supabase)
│   ├── theme/           # Tema da aplicação
│   └── utils/           # Utilitários (Responsive)
├── features/
│   ├── auth/            # Autenticação (Login, Registro)
│   ├── client/          # Funcionalidades do Cliente
│   ├── studio/          # Funcionalidades do Estúdio
│   └── splash/          # Tela de Splash
└── main.dart            # Entry point
```

## 🔧 Configuração

### Pré-requisitos

- Flutter SDK (3.8.1 ou superior)
- Conta no Supabase
- Projeto Supabase configurado com o schema fornecido

### Instalação

1. Clone o repositório:
```bash
git clone <repository-url>
cd studio_flow
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure o Supabase:
   - O arquivo `lib/core/config/supabase_config.dart` já está configurado com as credenciais do projeto
   - Certifique-se de que o schema do banco de dados foi executado no Supabase

4. Execute o aplicativo:
```bash
flutter run
```

## 📊 Banco de Dados

O schema do banco de dados está disponível em `database_schema.sql`. Execute este arquivo no seu projeto Supabase antes de usar o aplicativo.

## 🎨 Design

O aplicativo segue um design mobile-first e responsivo:
- **Mobile**: Layout otimizado para telas pequenas
- **Tablet**: Layout adaptado para telas médias
- **Desktop/Web**: Layout expandido para telas grandes

Todos os componentes respeitam a SafeArea para garantir que o conteúdo não seja sobreposto por barras do sistema.

## 🔐 Autenticação

- **Clientes**: Podem se cadastrar livremente via aplicativo
- **Estúdios**: Cadastro realizado apenas pelo admin (via Supabase)
- **Admin**: Acesso administrativo completo

## 📝 Próximos Passos

- [ ] Implementar notificações via Brevo
- [ ] Adicionar relatórios detalhados para estúdios
- [ ] Implementar sistema de avaliações completo
- [ ] Adicionar configuração de horários de funcionamento
- [ ] Implementar bloqueios de horários
- [ ] Adicionar perfil de usuário
- [ ] Melhorar tratamento de erros
- [ ] Adicionar testes unitários e de integração

## 📄 Licença

Este projeto é privado e proprietário.

---

Desenvolvido com ❤️ usando Flutter
