-- Migração SQL para criar a tabela "profiles" no Supabase
-- 
-- Esta tabela armazena informações adicionais do perfil do usuário
-- além dos dados básicos de autenticação.
-- 
-- INSTRUÇÕES:
-- 1. Acesse o Supabase Dashboard (https://app.supabase.com)
-- 2. Vá em "SQL Editor"
-- 3. Cole este código SQL
-- 4. Execute a query
-- 
-- A tabela será criada com:
-- - id: UUID que referencia auth.users (chave primária)
-- - name: Nome do usuário
-- - email: Email do usuário (mantido para facilitar consultas)
-- - created_at: Timestamp de criação (preenchido automaticamente)
-- - updated_at: Timestamp de atualização (atualizado automaticamente)

-- Cria a tabela profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilita Row Level Security (RLS) para segurança
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ler apenas seu próprio perfil
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Política: Usuários podem inserir apenas seu próprio perfil
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Política: Usuários podem atualizar apenas seu próprio perfil
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Função para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

