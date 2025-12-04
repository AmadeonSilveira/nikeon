-- ============================================
-- MIGRATION: 011_match_participants.sql
-- ============================================
-- Cria a tabela de participantes de partidas
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.

-- ============================================
-- TABELA: match_participants
-- ============================================
-- Armazena os participantes de cada partida, incluindo:
-- - Jogadores registrados (user_id não nulo)
-- - Convidados (user_id nulo, name preenchido)
-- - Informações de vitória e pontuação
CREATE TABLE IF NOT EXISTS public.match_participants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- Nome do jogador (do profile se user_id não nulo, ou nome do convidado)
  is_winner BOOLEAN DEFAULT false NOT NULL,
  score INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Habilita Row Level Security na tabela match_participants
ALTER TABLE public.match_participants ENABLE ROW LEVEL SECURITY;

-- Remove políticas existentes (se houver) para recriar
DROP POLICY IF EXISTS "Users can view participants of own matches" ON public.match_participants;
DROP POLICY IF EXISTS "Users can insert participants of own matches" ON public.match_participants;
DROP POLICY IF EXISTS "Users can update participants of own matches" ON public.match_participants;
DROP POLICY IF EXISTS "Users can delete participants of own matches" ON public.match_participants;

-- Política: Usuários podem ver participantes apenas de suas próprias partidas
CREATE POLICY "Users can view participants of own matches"
  ON public.match_participants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_participants.match_id
      AND matches.user_id = auth.uid()
    )
  );

-- Política: Usuários podem inserir participantes apenas em suas próprias partidas
CREATE POLICY "Users can insert participants of own matches"
  ON public.match_participants
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_participants.match_id
      AND matches.user_id = auth.uid()
    )
  );

-- Política: Usuários podem atualizar participantes apenas de suas próprias partidas
CREATE POLICY "Users can update participants of own matches"
  ON public.match_participants
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_participants.match_id
      AND matches.user_id = auth.uid()
    )
  );

-- Política: Usuários podem deletar participantes apenas de suas próprias partidas
CREATE POLICY "Users can delete participants of own matches"
  ON public.match_participants
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.matches
      WHERE matches.id = match_participants.match_id
      AND matches.user_id = auth.uid()
    )
  );

-- ============================================
-- ÍNDICES
-- ============================================
-- Índices para melhorar performance das consultas
CREATE INDEX IF NOT EXISTS idx_match_participants_match_id ON public.match_participants(match_id);
CREATE INDEX IF NOT EXISTS idx_match_participants_user_id ON public.match_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_match_participants_name ON public.match_participants(name);

-- Comentários para documentação
COMMENT ON TABLE public.match_participants IS 'Tabela de participantes de partidas (jogadores registrados e convidados)';
COMMENT ON COLUMN public.match_participants.id IS 'ID único do participante';
COMMENT ON COLUMN public.match_participants.match_id IS 'ID da partida';
COMMENT ON COLUMN public.match_participants.user_id IS 'ID do usuário (null para convidados)';
COMMENT ON COLUMN public.match_participants.name IS 'Nome do participante (do profile se user_id não nulo, ou nome do convidado)';
COMMENT ON COLUMN public.match_participants.is_winner IS 'Indica se o participante venceu a partida';
COMMENT ON COLUMN public.match_participants.score IS 'Pontuação obtida pelo participante (opcional)';

