-- ============================================
-- MIGRATION: 010_add_scoring_config_to_games.sql
-- ============================================
-- Adiciona a coluna scoring_config como JSONB em games
-- Esta migration é idempotente e pode ser executada múltiplas vezes.

ALTER TABLE public.games
  ADD COLUMN IF NOT EXISTS scoring_config JSONB DEFAULT '{}'::JSONB;

COMMENT ON COLUMN public.games.scoring_config IS
  'Configurações dinâmicas de pontuação utilizadas na tela de registrar partida';




