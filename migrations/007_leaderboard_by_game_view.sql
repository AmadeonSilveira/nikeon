-- ============================================
-- MIGRATION: 007_leaderboard_by_game_view.sql
-- ============================================
-- Cria uma VIEW com JOIN explícito entre leaderboard_by_game e profiles
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.
-- 
-- Objetivo: Resolver o problema do PostgREST que não consegue fazer
-- join automático entre leaderboard_by_game e profiles.

-- ============================================
-- VIEW: leaderboard_by_game_view
-- ============================================
-- View que combina dados do ranking por jogo com dados do perfil do usuário
DROP VIEW IF EXISTS public.leaderboard_by_game_view;

CREATE VIEW public.leaderboard_by_game_view AS
SELECT 
  lb.user_id,
  lb.game_id,
  lb.score,
  lb.wins,
  lb.losses,
  lb.matches,
  p.name AS profile_name,
  p.email AS profile_email
FROM public.leaderboard_by_game lb
LEFT JOIN public.profiles p ON p.id = lb.user_id;

-- Comentários para documentação
COMMENT ON VIEW public.leaderboard_by_game_view IS 
  'View que combina ranking por jogo com dados do perfil do usuário';

-- ============================================
-- POLÍTICAS RLS PARA A VIEW
-- ============================================
-- A view herda as políticas RLS da tabela base leaderboard_by_game
-- Não é necessário criar políticas específicas para a view,
-- pois ela apenas expõe os dados da tabela base com JOIN.

