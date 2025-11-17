-- Migração SQL para criar a tabela "games" no Supabase
-- 
-- Esta tabela armazena os jogos cadastrados pelos usuários,
-- incluindo jogos base e suas expansões.
-- 
-- INSTRUÇÕES:
-- 1. Acesse o Supabase Dashboard (https://app.supabase.com)
-- 2. Vá em "SQL Editor"
-- 3. Cole este código SQL
-- 4. Execute a query
-- 
-- A tabela será criada com Row Level Security (RLS) habilitado,
-- garantindo que cada usuário só possa ver e modificar seus próprios jogos.

-- ============================================
-- TABELA: games
-- ============================================
-- Armazena os jogos cadastrados pelos usuários
CREATE TABLE IF NOT EXISTS public.games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  min_players SMALLINT,
  max_players SMALLINT,
  play_time_minutes INTEGER,
  image_url TEXT,
  parent_game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
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

-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_games_user_id ON public.games(user_id);
CREATE INDEX IF NOT EXISTS idx_games_name ON public.games(name);
CREATE INDEX IF NOT EXISTS idx_games_parent_game_id ON public.games(parent_game_id);

-- Comentários nas colunas para documentação
COMMENT ON TABLE public.games IS 'Tabela de jogos cadastrados pelos usuários';
COMMENT ON COLUMN public.games.parent_game_id IS 'Se não nulo, indica que este é uma expansão do jogo referenciado';

