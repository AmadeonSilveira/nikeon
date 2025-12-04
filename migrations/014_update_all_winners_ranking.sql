-- ============================================
-- MIGRATION: 014_update_all_winners_ranking.sql
-- ============================================
-- Atualiza os triggers para considerar TODOS os participantes vencedores,
-- não apenas o dono da partida
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- FUNÇÃO: handle_participant_winner_ranking
-- ============================================
-- Atualiza o ranking quando um participante vencedor é inserido ou atualizado
-- 
-- Esta função atualiza o ranking global e por jogo para TODOS os participantes
-- vencedores, não apenas o dono da partida.
-- 
-- Fórmula de pontuação:
-- - Se o participante vencedor tiver pontuação (score) informada, usa essa pontuação
-- - Caso contrário, usa a fórmula padrão: 3 pontos por vitória
-- Esta função é executada com SECURITY DEFINER para contornar RLS
CREATE OR REPLACE FUNCTION public.handle_participant_winner_ranking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  match_record RECORD;
  found_game_id UUID;
  score_increment INTEGER;
  participant_user_id UUID;
BEGIN
  -- Só processa se o participante for vencedor e tiver user_id (não é convidado)
  IF NOT NEW.is_winner OR NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  participant_user_id := NEW.user_id;

  -- Busca informações da partida
  SELECT id, game_name, user_id INTO match_record
  FROM public.matches
  WHERE id = NEW.match_id;

  -- Se não encontrou a partida, retorna
  IF match_record.id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Calcula o incremento de score baseado na pontuação do participante
  IF NEW.score IS NOT NULL AND NEW.score > 0 THEN
    score_increment := NEW.score;
  ELSE
    score_increment := 3; -- Fórmula padrão: cada vitória vale 3 pontos
  END IF;

  -- ============================================
  -- ATUALIZA RANKING GLOBAL
  -- ============================================
  -- Atualiza o ranking de TODOS os participantes vencedores
  -- Se o usuário for o dono da partida, o trigger de matches já atualizou,
  -- então precisamos ajustar (subtrair o que foi adicionado e adicionar o correto)
  IF participant_user_id = match_record.user_id THEN
    -- É o dono da partida: ajusta o que foi feito pelo trigger de matches
    -- O trigger de matches adicionou baseado no campo result, mas agora
    -- sabemos que ele é vencedor pelos participantes, então ajustamos
    UPDATE public.leaderboard
    SET
      score = leaderboard.score - 3 + score_increment, -- Remove 3 padrão, adiciona pontuação correta
      wins = leaderboard.wins, -- Já foi incrementado, mantém
      losses = GREATEST(0, leaderboard.losses - 1), -- Remove a derrota que foi contada
      matches = leaderboard.matches -- Mantém (já foi incrementado)
    WHERE user_id = participant_user_id;
  ELSE
    -- Não é o dono: apenas adiciona normalmente
    INSERT INTO public.leaderboard (user_id, score, wins, losses, matches)
    VALUES (
      participant_user_id,
      score_increment,
      1, -- vitória
      0, -- não é derrota
      1  -- uma partida
    )
    ON CONFLICT (user_id) DO UPDATE
    SET
      score = leaderboard.score + score_increment,
      wins = leaderboard.wins + 1,
      matches = leaderboard.matches + 1;
  END IF;

  -- ============================================
  -- ATUALIZA RANKING POR JOGO
  -- ============================================
  -- Tenta encontrar o game_id pelo nome do jogo
  SELECT id INTO found_game_id
  FROM public.games
  WHERE name = match_record.game_name
  LIMIT 1;

  -- Se encontrou o jogo, atualiza o ranking por jogo
  IF found_game_id IS NOT NULL THEN
    IF participant_user_id = match_record.user_id THEN
      -- É o dono: ajusta o que foi feito pelo trigger de matches
      UPDATE public.leaderboard_by_game
      SET
        score = leaderboard_by_game.score - 3 + score_increment,
        wins = leaderboard_by_game.wins,
        losses = GREATEST(0, leaderboard_by_game.losses - 1),
        matches = leaderboard_by_game.matches
      WHERE user_id = participant_user_id AND game_id = found_game_id;
    ELSE
      -- Não é o dono: apenas adiciona normalmente
      INSERT INTO public.leaderboard_by_game (user_id, game_id, score, wins, losses, matches)
      VALUES (
        participant_user_id,
        found_game_id,
        score_increment,
        1, -- vitória
        0, -- não é derrota
        1  -- uma partida
      )
      ON CONFLICT (user_id, game_id) DO UPDATE
      SET
        score = leaderboard_by_game.score + score_increment,
        wins = leaderboard_by_game.wins + 1,
        matches = leaderboard_by_game.matches + 1;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================
-- FUNÇÃO: handle_participant_loser_ranking
-- ============================================
-- Atualiza o ranking quando um participante perdedor é inserido ou atualizado
-- 
-- Esta função atualiza o ranking global e por jogo para participantes perdedores
-- que têm user_id (não são convidados).
-- Esta função é executada com SECURITY DEFINER para contornar RLS
CREATE OR REPLACE FUNCTION public.handle_participant_loser_ranking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  match_record RECORD;
  found_game_id UUID;
  participant_user_id UUID;
BEGIN
  -- Só processa se o participante NÃO for vencedor e tiver user_id (não é convidado)
  IF NEW.is_winner OR NEW.user_id IS NULL THEN
    RETURN NEW;
  END IF;

  participant_user_id := NEW.user_id;

  -- Busca informações da partida
  SELECT id, game_name, user_id INTO match_record
  FROM public.matches
  WHERE id = NEW.match_id;

  -- Se não encontrou a partida, retorna
  IF match_record.id IS NULL THEN
    RETURN NEW;
  END IF;

  -- ============================================
  -- ATUALIZA RANKING GLOBAL
  -- ============================================
  -- Se o usuário for o dono da partida, o trigger de matches já atualizou
  -- (adicionou uma derrota), então não precisamos fazer nada (já está correto)
  -- Se não for o dono, adiciona a derrota normalmente
  IF participant_user_id != match_record.user_id THEN
    INSERT INTO public.leaderboard (user_id, score, wins, losses, matches)
    VALUES (
      participant_user_id,
      0, -- sem pontuação (derrota)
      0, -- não é vitória
      1, -- derrota
      1  -- uma partida
    )
    ON CONFLICT (user_id) DO UPDATE
    SET
      losses = leaderboard.losses + 1,
      matches = leaderboard.matches + 1;
  END IF;

  -- ============================================
  -- ATUALIZA RANKING POR JOGO
  -- ============================================
  -- Tenta encontrar o game_id pelo nome do jogo
  SELECT id INTO found_game_id
  FROM public.games
  WHERE name = match_record.game_name
  LIMIT 1;

  -- Se encontrou o jogo, atualiza o ranking por jogo
  -- Se não for o dono, adiciona a derrota normalmente
  IF found_game_id IS NOT NULL AND participant_user_id != match_record.user_id THEN
    INSERT INTO public.leaderboard_by_game (user_id, game_id, score, wins, losses, matches)
    VALUES (
      participant_user_id,
      found_game_id,
      0, -- sem pontuação (derrota)
      0, -- não é vitória
      1, -- derrota
      1  -- uma partida
    )
    ON CONFLICT (user_id, game_id) DO UPDATE
    SET
      losses = leaderboard_by_game.losses + 1,
      matches = leaderboard_by_game.matches + 1;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================
-- TRIGGERS
-- ============================================
-- Remove triggers existentes (se houver) para recriar
DROP TRIGGER IF EXISTS trg_match_participants_winner_ranking ON public.match_participants;
DROP TRIGGER IF EXISTS trg_match_participants_loser_ranking ON public.match_participants;

-- Trigger: Atualiza ranking quando um participante vencedor é inserido/atualizado
CREATE TRIGGER trg_match_participants_winner_ranking
  AFTER INSERT OR UPDATE ON public.match_participants
  FOR EACH ROW
  WHEN (NEW.is_winner = true AND NEW.user_id IS NOT NULL)
  EXECUTE FUNCTION public.handle_participant_winner_ranking();

-- Trigger: Atualiza ranking quando um participante perdedor é inserido/atualizado
CREATE TRIGGER trg_match_participants_loser_ranking
  AFTER INSERT OR UPDATE ON public.match_participants
  FOR EACH ROW
  WHEN (NEW.is_winner = false AND NEW.user_id IS NOT NULL)
  EXECUTE FUNCTION public.handle_participant_loser_ranking();

-- ============================================
-- ATUALIZA FUNÇÕES EXISTENTES PARA EVITAR DUPLICAÇÃO
-- ============================================
-- Modifica as funções existentes para não atualizar o dono da partida
-- se já houver participantes (os triggers de participantes já fazem isso)

-- Atualiza handle_leaderboard_update para verificar se há participantes
-- Se houver participantes, não atualiza (os triggers de participantes fazem isso)
CREATE OR REPLACE FUNCTION public.handle_leaderboard_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_participants BOOLEAN;
  score_increment INTEGER;
  user_is_winner BOOLEAN;
  participant_score INTEGER;
BEGIN
  -- Verifica se há participantes para esta partida
  SELECT EXISTS (
    SELECT 1 FROM public.match_participants 
    WHERE match_id = NEW.id 
    LIMIT 1
  ) INTO has_participants;

  -- Se houver participantes, os triggers de participantes já atualizam o ranking
  -- então não precisamos atualizar aqui (evita duplicação)
  IF has_participants THEN
    RETURN NEW;
  END IF;

  -- Se não houver participantes, usa a lógica antiga (compatibilidade com partidas antigas)
  user_is_winner := (NEW.result = 'win');

  IF user_is_winner THEN
    score_increment := 3; -- Fórmula padrão: cada vitória vale 3 pontos
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

-- Atualiza handle_leaderboard_by_game_update para verificar se há participantes
CREATE OR REPLACE FUNCTION public.handle_leaderboard_by_game_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  found_game_id UUID;
  has_participants BOOLEAN;
  score_increment INTEGER;
  user_is_winner BOOLEAN;
BEGIN
  -- Verifica se há participantes para esta partida
  SELECT EXISTS (
    SELECT 1 FROM public.match_participants 
    WHERE match_id = NEW.id 
    LIMIT 1
  ) INTO has_participants;

  -- Se houver participantes, os triggers de participantes já atualizam o ranking
  IF has_participants THEN
    RETURN NEW;
  END IF;

  -- Tenta encontrar o game_id pelo nome do jogo
  SELECT id INTO found_game_id
  FROM public.games
  WHERE name = NEW.game_name
  LIMIT 1;

  -- Se não encontrou o jogo, não atualiza o ranking por jogo
  IF found_game_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Se não houver participantes, usa a lógica antiga
  user_is_winner := (NEW.result = 'win');

  IF user_is_winner THEN
    score_increment := 3; -- Fórmula padrão: cada vitória vale 3 pontos
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
COMMENT ON FUNCTION public.handle_participant_winner_ranking() IS 
  'Atualiza o ranking global e por jogo quando um participante vencedor é inserido/atualizado';
COMMENT ON FUNCTION public.handle_participant_loser_ranking() IS 
  'Atualiza o ranking global e por jogo quando um participante perdedor é inserido/atualizado';
COMMENT ON FUNCTION public.handle_leaderboard_update() IS 
  'Atualiza o ranking global quando uma partida é inserida (apenas se não houver participantes)';
COMMENT ON FUNCTION public.handle_leaderboard_by_game_update() IS 
  'Atualiza o ranking por jogo quando uma partida é inserida (apenas se não houver participantes)';

