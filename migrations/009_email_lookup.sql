-- ============================================
-- MIGRATION: 009_email_lookup.sql
-- ============================================
-- Cria função segura para verificação de email sem expor dados pessoais
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.
-- 
-- Objetivo: Permitir verificação de disponibilidade de email durante o cadastro
-- sem violar RLS e sem expor dados pessoais dos perfis.

-- ============================================
-- FUNÇÃO: email_exists
-- ============================================
-- Função segura que verifica se um email já está cadastrado
-- 
-- Características:
-- - SECURITY DEFINER: Executa com permissões elevadas, contornando RLS
-- - Retorna apenas boolean (true/false)
-- - Nunca expõe dados pessoais
-- - Normaliza o email (trim + lowercase) antes de verificar
DROP FUNCTION IF EXISTS public.email_exists(TEXT);

CREATE FUNCTION public.email_exists(email_param TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  email_count INTEGER;
BEGIN
  -- Normaliza o email (trim + lowercase)
  email_param := LOWER(TRIM(email_param));
  
  -- Valida formato básico
  IF email_param = '' OR email_param NOT LIKE '%@%' THEN
    RETURN FALSE;
  END IF;
  
  -- Conta quantos perfis têm esse email
  -- A função SECURITY DEFINER permite ler mesmo com RLS ativo
  SELECT COUNT(*) INTO email_count
  FROM public.profiles
  WHERE LOWER(TRIM(email)) = email_param;
  
  -- Retorna true se encontrou pelo menos um registro
  RETURN email_count > 0;
END;
$$;

-- ============================================
-- COMENTÁRIOS PARA DOCUMENTAÇÃO
-- ============================================
COMMENT ON FUNCTION public.email_exists(TEXT) IS 
  'Verifica se um email já está cadastrado na tabela profiles. Retorna TRUE se existe, FALSE caso contrário. Função segura que não expõe dados pessoais.';

-- ============================================
-- NOTA SOBRE RLS
-- ============================================
-- A função email_exists() usa SECURITY DEFINER, o que significa que
-- ela executa com permissões elevadas e pode ler a tabela profiles
-- mesmo com RLS ativado, sem expor dados pessoais (retorna apenas boolean).
-- 
-- As políticas RLS existentes continuam protegendo a tabela profiles
-- para operações diretas (SELECT, INSERT, UPDATE, DELETE).
-- 
-- A função pode ser chamada via RPC do Supabase:
-- SELECT email_exists('email@exemplo.com');

