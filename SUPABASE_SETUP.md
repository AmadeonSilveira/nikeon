# Configuração do Supabase para o Nikeon

Este documento explica como configurar o Supabase no projeto Nikeon.

## Passo 1: Criar um projeto no Supabase

1. Acesse [https://app.supabase.com](https://app.supabase.com)
2. Crie uma conta ou faça login
3. Clique em "New Project"
4. Preencha os dados do projeto:
   - Nome do projeto
   - Senha do banco de dados
   - Região (escolha a mais próxima)
5. Aguarde o projeto ser criado (pode levar alguns minutos)

## Passo 2: Obter as credenciais

1. No dashboard do projeto, vá em **Settings** → **API**
2. Copie os seguintes valores:
   - **Project URL** (ex: `https://xxxxx.supabase.co`)
   - **anon public** key (chave anônima pública)

## Passo 3: Configurar o app Flutter

1. Abra o arquivo `lib/main.dart`
2. Localize as linhas:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```
3. Substitua:
   - `YOUR_SUPABASE_URL` pela **Project URL** copiada
   - `YOUR_SUPABASE_ANON_KEY` pela **anon public** key copiada

## Passo 4: Criar a tabela "profiles"

1. No dashboard do Supabase, vá em **SQL Editor**
2. Clique em **New Query**
3. Abra o arquivo `migrations/create_profiles_table.sql` deste projeto
4. Cole todo o conteúdo SQL no editor
5. Clique em **Run** para executar a query
6. Verifique se a tabela foi criada em **Table Editor** → **profiles**

## Passo 5: Instalar dependências

Execute no terminal:

```bash
flutter pub get
```

## Passo 6: Testar o app

1. Execute o app: `flutter run`
2. Tente criar uma conta
3. Faça login com a conta criada
4. Verifique se o perfil foi criado na tabela "profiles" no Supabase

## Estrutura da tabela "profiles"

A tabela `profiles` contém:
- `id` (UUID): Referencia `auth.users(id)`, chave primária
- `name` (TEXT): Nome do usuário
- `email` (TEXT): Email do usuário
- `created_at` (TIMESTAMP): Data de criação (automático)
- `updated_at` (TIMESTAMP): Data de atualização (automático)

## Segurança (RLS)

A tabela está protegida com Row Level Security (RLS):
- Usuários só podem ver seu próprio perfil
- Usuários só podem inserir seu próprio perfil
- Usuários só podem atualizar seu próprio perfil

## Troubleshooting

### Erro: "Invalid API key"
- Verifique se copiou a chave correta (anon public, não service_role)
- Verifique se não há espaços extras nas credenciais

### Erro: "relation 'profiles' does not exist"
- Execute a migração SQL novamente
- Verifique se está no projeto correto do Supabase

### Erro: "new row violates row-level security policy"
- Verifique se as políticas RLS estão configuradas corretamente
- Execute novamente a migração SQL completa

