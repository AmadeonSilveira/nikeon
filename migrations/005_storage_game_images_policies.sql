-- ============================================
-- MIGRATION: 005_storage_game_images_policies.sql
-- ============================================
-- Cria políticas de segurança (RLS) para o bucket de imagens de jogos
-- 
-- Esta migration é idempotente e pode ser executada múltiplas vezes
-- sem causar erros.
-- 
-- IMPORTANTE: O bucket "game-images" deve ser criado manualmente no Supabase Dashboard
-- antes de executar esta migration.
-- 
-- Estrutura de pastas esperada:
-- game-images/{user_id}/games/{game_id}/{filename}

-- ============================================
-- POLÍTICAS DE STORAGE
-- ============================================

-- Remove políticas existentes (se houver) para recriar
DROP POLICY IF EXISTS "Users can upload own game images" ON storage.objects;
DROP POLICY IF EXISTS "Users can read game images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own game images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own game images" ON storage.objects;

-- ============================================
-- POLÍTICA: INSERT (Upload)
-- ============================================
-- Usuários autenticados podem fazer upload de imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can upload own game images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- POLÍTICA: SELECT (Leitura)
-- ============================================
-- Usuários autenticados podem ler imagens do bucket
-- (todas as imagens são legíveis por usuários autenticados)
CREATE POLICY "Users can read game images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'game-images');

-- ============================================
-- POLÍTICA: UPDATE (Atualização)
-- ============================================
-- Usuários autenticados podem atualizar suas próprias imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can update own game images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- POLÍTICA: DELETE (Deleção)
-- ============================================
-- Usuários autenticados podem deletar suas próprias imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can delete own game images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Comentários para documentação
COMMENT ON POLICY "Users can upload own game images" ON storage.objects IS 
  'Permite que usuários autenticados façam upload de imagens apenas na pasta com seu próprio user_id';
COMMENT ON POLICY "Users can read game images" ON storage.objects IS 
  'Permite que usuários autenticados leiam todas as imagens do bucket game-images';
COMMENT ON POLICY "Users can update own game images" ON storage.objects IS 
  'Permite que usuários autenticados atualizem suas próprias imagens';
COMMENT ON POLICY "Users can delete own game images" ON storage.objects IS 
  'Permite que usuários autenticados deletem suas próprias imagens';

