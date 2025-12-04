-- ============================================
-- MIGRATION: 013_update_ranking_from_participants.sql
-- ============================================
-- Atualiza as funções de ranking para considerar os participantes vencedores
-- em vez de apenas o campo result da tabela matches
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- FUNÇÃO: handle_leaderboard_update
-- ============================================
-- Atualiza o ranking global quando uma partida é inserida
-- 
-- Agora considera os participantes vencedores da partida.
-- Se o usuário atual (user_id da partida) estiver entre os vencedores,
-- conta como vitória, caso contrário como derrota.
-- 
-- Fórmula de pontuação:
-- - Se o participante vencedor tiver pontuação (score) informada, usa essa pontuação
-- - Caso contrário, usa a fórmula padrão: 3 pontos por vitória
-- Esta função é executada com SECURITY DEFINER para contornar RLS
CREATE OR REPLACE FUNCTION public.handle_leaderboard_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  score_increment INTEGER;
  user_is_winner BOOLEAN;
  participant_score INTEGER;
BEGIN
  -- Verifica se o usuário da partida está entre os vencedores
  -- Busca nos participantes da partida recém-criada
  -- Se não encontrar participantes (trigger pode rodar antes), usa o campo result como fallback
  SELECT COALESCE(
    (SELECT true FROM public.match_participants 
     WHERE match_id = NEW.id 
       AND user_id = NEW.user_id 
       AND is_winner = true 
     LIMIT 1),
    (NEW.result = 'win')
  ) INTO user_is_winner;

  -- Busca a pontuação do participante vencedor (se houver)
  SELECT COALESCE(score, 0) INTO participant_score
  FROM public.match_participants
  WHERE match_id = NEW.id
    AND user_id = NEW.user_id
    AND is_winner = true
  LIMIT 1;

  -- Calcula o incremento de score baseado no resultado e pontuação
  -- Se o usuário venceu e tem pontuação, usa a pontuação
  -- Caso contrário, usa a fórmula padrão: vitória = 3 pontos
  IF user_is_winner THEN
    IF participant_score > 0 THEN
      score_increment := participant_score;
    ELSE
      score_increment := 3; -- Fórmula padrão: cada vitória vale 3 pontos
    END IF;
  ELSE
    score_increment := 0;
  END IF;

  -- Insere ou atualiza o registro no ranking global
  INSERT INTO public.leaderboard (user_id, score, wins, losses, matches)
  VALUES (
    NEW.user_id,
    score_increment,
    CASE WHEN user_is_winner THEN 1 ELSE 0 END,
    CASE WHEN user_is_winner THEN 0 ELSE 1 END,
    1
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    score = leaderboard.score + score_increment,
    wins = leaderboard.wins + CASE WHEN user_is_winner THEN 1 ELSE 0 END,
    losses = leaderboard.losses + CASE WHEN user_is_winner THEN 0 ELSE 1 END,
    matches = leaderboard.matches + 1;

  RETURN NEW;
END;
$$;

-- ============================================
-- FUNÇÃO: handle_leaderboard_by_game_update
-- ============================================
-- Atualiza o ranking por jogo quando uma partida é inserida
-- 
-- Agora considera os participantes vencedores da partida.
-- Se o usuário atual (user_id da partida) estiver entre os vencedores,
-- conta como vitória, caso contrário como derrota.
-- 
-- Fórmula de pontuação:
-- - Se o participante vencedor tiver pontuação (score) informada, usa essa pontuação
-- - Caso contrário, usa a fórmula padrão: 3 pontos por vitória
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
  user_is_winner BOOLEAN;
  participant_score INTEGER;
BEGIN
  -- Tenta encontrar o game_id pelo nome do jogo
  -- Procura em todos os jogos (agora visíveis globalmente)
  SELECT id INTO found_game_id
  FROM public.games
  WHERE name = NEW.game_name
  LIMIT 1;

  -- Se não encontrou o jogo, não atualiza o ranking por jogo
  IF found_game_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Verifica se o usuário da partida está entre os vencedores
  -- Busca nos participantes da partida recém-criada
  -- Se não encontrar participantes (trigger pode rodar antes), usa o campo result como fallback
  SELECT COALESCE(
    (SELECT true FROM public.match_participants 
     WHERE match_id = NEW.id 
       AND user_id = NEW.user_id 
       AND is_winner = true 
     LIMIT 1),
    (NEW.result = 'win')
  ) INTO user_is_winner;

  -- Busca a pontuação do participante vencedor (se houver)
  SELECT COALESCE(score, 0) INTO participant_score
  FROM public.match_participants
  WHERE match_id = NEW.id
    AND user_id = NEW.user_id
    AND is_winner = true
  LIMIT 1;

  -- Calcula o incremento de score baseado no resultado e pontuação
  -- Se o usuário venceu e tem pontuação, usa a pontuação
  -- Caso contrário, usa a fórmula padrão: vitória = 3 pontos
  IF user_is_winner THEN
    IF participant_score > 0 THEN
      score_increment := participant_score;
    ELSE
      score_increment := 3; -- Fórmula padrão: cada vitória vale 3 pontos
    END IF;
  ELSE
    score_increment := 0;
  END IF;

  -- Insere ou atualiza o registro no ranking por jogo
  INSERT INTO public.leaderboard_by_game (user_id, game_id, score, wins, losses, matches)
  VALUES (
    NEW.user_id,
    found_game_id,
    score_increment,
    CASE WHEN user_is_winner THEN 1 ELSE 0 END,
    CASE WHEN user_is_winner THEN 0 ELSE 1 END,
    1
  )
  ON CONFLICT (user_id, game_id) DO UPDATE
  SET
    score = leaderboard_by_game.score + score_increment,
    wins = leaderboard_by_game.wins + CASE WHEN user_is_winner THEN 1 ELSE 0 END,
    losses = leaderboard_by_game.losses + CASE WHEN user_is_winner THEN 0 ELSE 1 END,
    matches = leaderboard_by_game.matches + 1;

  RETURN NEW;
END;
$$;


-- Comentários para documentação
COMMENT ON FUNCTION public.handle_leaderboard_update() IS 
  'Atualiza o ranking global quando uma partida é inserida, considerando participantes vencedores e suas pontuações';
COMMENT ON FUNCTION public.handle_leaderboard_by_game_update() IS 
  'Atualiza o ranking por jogo quando uma partida é inserida, considerando participantes vencedores e suas pontuações';

