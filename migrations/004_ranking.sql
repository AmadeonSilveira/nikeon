-- ============================================
-- MIGRATION: 004_ranking.sql
-- ============================================
-- Cria as tabelas de ranking e funções/triggers para atualização automática
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- TABELA: leaderboard (Ranking Global)
-- ============================================
-- Ranking global consolidado por usuário
CREATE TABLE IF NOT EXISTS public.leaderboard (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  score INTEGER DEFAULT 0 NOT NULL,
  wins INTEGER DEFAULT 0 NOT NULL,
  losses INTEGER DEFAULT 0 NOT NULL,
  matches INTEGER DEFAULT 0 NOT NULL
);

-- Habilita Row Level Security na tabela leaderboard
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

-- Remove políticas existentes (se houver) para recriar
DROP POLICY IF EXISTS "Authenticated users can view leaderboard" ON public.leaderboard;

-- Política: Usuários autenticados podem ver o ranking completo
CREATE POLICY "Authenticated users can view leaderboard"
  ON public.leaderboard
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- TABELA: leaderboard_by_game (Ranking por Jogo)
-- ============================================
-- Ranking específico por jogo (combinação usuário + jogo)
CREATE TABLE IF NOT EXISTS public.leaderboard_by_game (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_id UUID REFERENCES public.games(id) ON DELETE CASCADE NOT NULL,
  score INTEGER DEFAULT 0 NOT NULL,
  wins INTEGER DEFAULT 0 NOT NULL,
  losses INTEGER DEFAULT 0 NOT NULL,
  matches INTEGER DEFAULT 0 NOT NULL,
  PRIMARY KEY (user_id, game_id)
);

-- Habilita Row Level Security na tabela leaderboard_by_game
ALTER TABLE public.leaderboard_by_game ENABLE ROW LEVEL SECURITY;

-- Remove políticas existentes (se houver) para recriar
DROP POLICY IF EXISTS "Authenticated users can view leaderboard by game" ON public.leaderboard_by_game;

-- Política: Usuários autenticados podem ver o ranking por jogo
CREATE POLICY "Authenticated users can view leaderboard by game"
  ON public.leaderboard_by_game
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================
-- ÍNDICES
-- ============================================
-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_leaderboard_score ON public.leaderboard(score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_by_game_game_id ON public.leaderboard_by_game(game_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_by_game_score ON public.leaderboard_by_game(game_id, score DESC);

-- ============================================
-- FUNÇÃO: handle_leaderboard_update
-- ============================================
-- Atualiza o ranking global quando uma partida é inserida
-- 
-- Fórmula de pontuação: score = vitórias * 3
-- Esta função é executada com SECURITY DEFINER para contornar RLS
CREATE OR REPLACE FUNCTION public.handle_leaderboard_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  score_increment INTEGER;
BEGIN
  -- Calcula o incremento de score baseado no resultado
  -- Regra atual: cada vitória vale 3 pontos
  IF NEW.result = 'win' THEN
    score_increment := 3;
  ELSE
    score_increment := 0;
  END IF;

  -- Insere ou atualiza o registro no ranking global
  INSERT INTO public.leaderboard (user_id, score, wins, losses, matches)
  VALUES (
    NEW.user_id,
    score_increment,
    CASE WHEN NEW.result = 'win' THEN 1 ELSE 0 END,
    CASE WHEN NEW.result = 'loss' THEN 1 ELSE 0 END,
    1
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    score = leaderboard.score + score_increment,
    wins = leaderboard.wins + CASE WHEN NEW.result = 'win' THEN 1 ELSE 0 END,
    losses = leaderboard.losses + CASE WHEN NEW.result = 'loss' THEN 1 ELSE 0 END,
    matches = leaderboard.matches + 1;

  RETURN NEW;
END;
$$;

-- ============================================
-- FUNÇÃO: handle_leaderboard_by_game_update
-- ============================================
-- Atualiza o ranking por jogo quando uma partida é inserida
-- 
-- Procura o game_id correspondente baseado no nome do jogo.
-- Se o jogo não estiver cadastrado, ignora o registro.
-- Esta função é executada com SECURITY DEFINER para contornar RLS
CREATE OR REPLACE FUNCTION public.handle_leaderboard_by_game_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  found_game_id UUID;
  score_increment INTEGER;
BEGIN
  -- Tenta encontrar o game_id pelo nome do jogo
  -- Procura apenas nos jogos do próprio usuário
  SELECT id INTO found_game_id
  FROM public.games
  WHERE name = NEW.game_name
    AND user_id = NEW.user_id
  LIMIT 1;

  -- Se não encontrou o jogo, não atualiza o ranking por jogo
  IF found_game_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Calcula o incremento de score baseado no resultado
  -- Regra atual: cada vitória vale 3 pontos
  IF NEW.result = 'win' THEN
    score_increment := 3;
  ELSE
    score_increment := 0;
  END IF;

  -- Insere ou atualiza o registro no ranking por jogo
  INSERT INTO public.leaderboard_by_game (user_id, game_id, score, wins, losses, matches)
  VALUES (
    NEW.user_id,
    found_game_id,
    score_increment,
    CASE WHEN NEW.result = 'win' THEN 1 ELSE 0 END,
    CASE WHEN NEW.result = 'loss' THEN 1 ELSE 0 END,
    1
  )
  ON CONFLICT (user_id, game_id) DO UPDATE
  SET
    score = leaderboard_by_game.score + score_increment,
    wins = leaderboard_by_game.wins + CASE WHEN NEW.result = 'win' THEN 1 ELSE 0 END,
    losses = leaderboard_by_game.losses + CASE WHEN NEW.result = 'loss' THEN 1 ELSE 0 END,
    matches = leaderboard_by_game.matches + 1;

  RETURN NEW;
END;
$$;

-- ============================================
-- TRIGGERS
-- ============================================
-- Remove triggers existentes (se houver) para recriar
DROP TRIGGER IF EXISTS trg_matches_leaderboard ON public.matches;
DROP TRIGGER IF EXISTS trg_matches_leaderboard_by_game ON public.matches;

-- Trigger: Atualiza ranking global após inserir partida
CREATE TRIGGER trg_matches_leaderboard
  AFTER INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_leaderboard_update();

-- Trigger: Atualiza ranking por jogo após inserir partida
CREATE TRIGGER trg_matches_leaderboard_by_game
  AFTER INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_leaderboard_by_game_update();

-- Comentários para documentação
COMMENT ON TABLE public.leaderboard IS 'Ranking global consolidado por usuário';
COMMENT ON TABLE public.leaderboard_by_game IS 'Ranking específico por jogo (combinação usuário + jogo)';
COMMENT ON COLUMN public.leaderboard.score IS 'Pontuação total (vitórias * 3)';
COMMENT ON COLUMN public.leaderboard_by_game.score IS 'Pontuação total no jogo específico (vitórias * 3)';
COMMENT ON FUNCTION public.handle_leaderboard_update() IS 'Atualiza o ranking global quando uma partida é inserida';
COMMENT ON FUNCTION public.handle_leaderboard_by_game_update() IS 'Atualiza o ranking por jogo quando uma partida é inserida';

