-- ============================================
-- MIGRATION: 008_leaderboard_view.sql
-- ============================================
-- Cria uma VIEW com JOIN explícito entre leaderboard e profiles
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.
-- 
-- Objetivo: Garantir que o PostgREST consiga fazer o join corretamente
-- entre leaderboard e profiles, resolvendo o problema de nomes não aparecerem
-- no ranking global.

-- ============================================
-- VIEW: leaderboard_view
-- ============================================
-- View que combina dados do ranking global com dados do perfil do usuário
DROP VIEW IF EXISTS public.leaderboard_view;

CREATE VIEW public.leaderboard_view AS
SELECT 
  lb.user_id,
  lb.score,
  lb.wins,
  lb.losses,
  lb.matches,
  p.name AS profile_name,
  p.email AS profile_email
FROM public.leaderboard lb
LEFT JOIN public.profiles p ON p.id = lb.user_id;

-- Comentários para documentação
COMMENT ON VIEW public.leaderboard_view IS 
  'View que combina ranking global com dados do perfil do usuário';

-- ============================================
-- POLÍTICAS RLS PARA A VIEW
-- ============================================
-- A view herda as políticas RLS da tabela base leaderboard
-- Não é necessário criar políticas específicas para a view,
-- pois ela apenas expõe os dados da tabela base com JOIN.

