-- ============================================
-- MIGRATION: 012_profiles_global_visibility.sql
-- ============================================
-- Atualiza as políticas RLS da tabela profiles para permitir
-- que usuários autenticados vejam todos os perfis (necessário
-- para seleção de jogadores em partidas)
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- Remover política antiga de visualização
-- ============================================
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

-- ============================================
-- Criar nova política de visualização global
-- ============================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Authenticated users can view all profiles'
          AND tablename = 'profiles'
    ) THEN
        CREATE POLICY "Authenticated users can view all profiles"
        ON public.profiles
        FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

-- Comentários para documentação
COMMENT ON POLICY "Authenticated users can view all profiles" ON public.profiles IS
  'Permite que qualquer usuário autenticado visualize todos os perfis (necessário para seleção de jogadores)';

