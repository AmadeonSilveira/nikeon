-- ============================================================
-- MIGRATION: 006_games_global_visibility.sql (versão idempotente)
-- ============================================================

-- Objetivo:
--   - Jogos visíveis globalmente para qualquer usuário autenticado
--   - Apenas o criador pode editar/deletar
--   - Pode ser executada múltiplas vezes sem erro

-- ============================================================
-- Remover políticas antigas se existirem
-- ============================================================

DROP POLICY IF EXISTS "Users can view own games" ON public.games;
DROP POLICY IF EXISTS "Users can insert own games" ON public.games;
DROP POLICY IF EXISTS "Users can update own games" ON public.games;
DROP POLICY IF EXISTS "Users can delete own games" ON public.games;

-- ============================================================
-- Criar políticas NOVAS somente se ainda não existirem
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Anyone can view all games'
          AND tablename = 'games'
    ) THEN
        CREATE POLICY "Anyone can view all games"
        ON public.games
        FOR SELECT
        TO authenticated
        USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Users can insert own games'
          AND tablename = 'games'
    ) THEN
        CREATE POLICY "Users can insert own games"
        ON public.games
        FOR INSERT
        TO authenticated
        WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Users can update own games'
          AND tablename = 'games'
    ) THEN
        CREATE POLICY "Users can update own games"
        ON public.games
        FOR UPDATE
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Users can delete own games'
          AND tablename = 'games'
    ) THEN
        CREATE POLICY "Users can delete own games"
        ON public.games
        FOR DELETE
        TO authenticated
        USING (auth.uid() = user_id);
    END IF;
END $$;

-- ============================================================
-- Comentários (opcional)
-- ============================================================

COMMENT ON POLICY "Anyone can view all games" ON public.games IS
  'Permite que qualquer usuário autenticado visualize todos os jogos.';

COMMENT ON POLICY "Users can insert own games" ON public.games IS
  'Permite que usuários insiram apenas jogos com seu próprio user_id.';

COMMENT ON POLICY "Users can update own games" ON public.games IS
  'Permite que apenas o criador do jogo possa editá-lo.';

COMMENT ON POLICY "Users can delete own games" ON public.games IS
  'Permite que apenas o criador do jogo possa deletá-lo.';
