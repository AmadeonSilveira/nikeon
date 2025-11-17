-- Migração SQL para criar as tabelas de partidas no Supabase
-- 
-- Esta migração cria duas tabelas:
-- - matches: armazena as partidas jogadas pelos usuários
-- - games: armazena os jogos cadastrados pelos usuários
-- 
-- INSTRUÇÕES:
-- 1. Acesse o Supabase Dashboard (https://app.supabase.com)
-- 2. Vá em "SQL Editor"
-- 3. Cole este código SQL
-- 4. Execute a query
-- 
-- As tabelas serão criadas com Row Level Security (RLS) habilitado,
-- garantindo que cada usuário só possa ver e modificar seus próprios dados.

-- ============================================
-- TABELA: games
-- ============================================
-- Armazena os jogos cadastrados pelos usuários
CREATE TABLE IF NOT EXISTS public.games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilita Row Level Security na tabela games
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver apenas seus próprios jogos
CREATE POLICY "Users can view own games"
  ON public.games
  FOR SELECT
  USING (auth.uid() = user_id);

-- Política: Usuários podem inserir apenas seus próprios jogos
CREATE POLICY "Users can insert own games"
  ON public.games
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: Usuários podem atualizar apenas seus próprios jogos
CREATE POLICY "Users can update own games"
  ON public.games
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Política: Usuários podem deletar apenas seus próprios jogos
CREATE POLICY "Users can delete own games"
  ON public.games
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- TABELA: matches
-- ============================================
-- Armazena as partidas jogadas pelos usuários
CREATE TABLE IF NOT EXISTS public.matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_name TEXT NOT NULL,
  result TEXT NOT NULL CHECK (result IN ('win', 'loss')),
  played_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilita Row Level Security na tabela matches
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

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

-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_matches_user_id ON public.matches(user_id);
CREATE INDEX IF NOT EXISTS idx_matches_played_at ON public.matches(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_games_user_id ON public.games(user_id);

