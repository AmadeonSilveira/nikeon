-- ============================================
-- MIGRATION: 003_matches.sql
-- ============================================
-- Cria a tabela de partidas jogadas pelos usuários
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- ENUM: match_result
-- ============================================
-- Tipo enumerado para resultados de partidas
DO $$ BEGIN
  CREATE TYPE public.match_result AS ENUM ('win', 'loss');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- TABELA: matches
-- ============================================
-- Armazena as partidas jogadas pelos usuários
CREATE TABLE IF NOT EXISTS public.matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_id UUID REFERENCES public.games(id) ON DELETE SET NULL,
  game_name TEXT NOT NULL,
  result public.match_result NOT NULL,
  played_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilita Row Level Security na tabela matches
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Remove políticas existentes (se houver) para recriar
DROP POLICY IF EXISTS "Users can view own matches" ON public.matches;
DROP POLICY IF EXISTS "Users can insert own matches" ON public.matches;
DROP POLICY IF EXISTS "Users can update own matches" ON public.matches;
DROP POLICY IF EXISTS "Users can delete own matches" ON public.matches;

-- Política: Usuários podem ver apenas suas próprias partidas
CREATE POLICY "Users can view own matches"
  ON public.matches
  FOR SELECT
  USING (auth.uid() = user_id);

-- Política: Usuários podem inserir apenas suas próprias partidas
CREATE POLICY "Users can insert own matches"
  ON public.matches
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: Usuários podem atualizar apenas suas próprias partidas
CREATE POLICY "Users can update own matches"
  ON public.matches
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Política: Usuários podem deletar apenas suas próprias partidas
CREATE POLICY "Users can delete own matches"
  ON public.matches
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- ÍNDICES
-- ============================================
-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_matches_user_id ON public.matches(user_id);
CREATE INDEX IF NOT EXISTS idx_matches_game_id ON public.matches(game_id);
CREATE INDEX IF NOT EXISTS idx_matches_result ON public.matches(result);
CREATE INDEX IF NOT EXISTS idx_matches_played_at ON public.matches(played_at DESC);

-- Comentários para documentação
COMMENT ON TABLE public.matches IS 'Tabela de partidas jogadas pelos usuários';
COMMENT ON COLUMN public.matches.id IS 'ID único da partida';
COMMENT ON COLUMN public.matches.user_id IS 'ID do usuário que jogou a partida';
COMMENT ON COLUMN public.matches.game_id IS 'ID do jogo (opcional, referencia games.id)';
COMMENT ON COLUMN public.matches.game_name IS 'Nome do jogo (backup de compatibilidade)';
COMMENT ON COLUMN public.matches.result IS 'Resultado da partida: win (vitória) ou loss (derrota)';
COMMENT ON COLUMN public.matches.played_at IS 'Data/hora em que a partida foi jogada';
COMMENT ON COLUMN public.matches.created_at IS 'Data/hora de criação do registro';

