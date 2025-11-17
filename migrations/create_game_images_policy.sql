-- Migração SQL para criar políticas de storage para imagens de jogos
-- 
-- Esta migração configura o bucket "game-images" no Supabase Storage
-- com políticas de segurança (RLS) para permitir que usuários façam
-- upload e leiam apenas suas próprias imagens.
-- 
-- INSTRUÇÕES:
-- 1. Acesse o Supabase Dashboard (https://app.supabase.com)
-- 2. Vá em "Storage"
-- 3. Crie um novo bucket chamado "game-images"
-- 4. Marque como PRIVADO (não público)
-- 5. Vá em "SQL Editor"
-- 6. Cole este código SQL
-- 7. Execute a query
-- 
-- IMPORTANTE: Execute primeiro a criação do bucket manualmente no dashboard,
-- depois execute este SQL para criar as políticas.

-- ============================================
-- POLÍTICAS DE STORAGE
-- ============================================

-- Política: Usuários autenticados podem fazer upload de imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can upload own game images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Política: Usuários autenticados podem ler imagens do bucket
-- (todas as imagens são legíveis por usuários autenticados)
CREATE POLICY "Users can read game images"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'game-images');

-- Política: Usuários autenticados podem atualizar suas próprias imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can update own game images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Política: Usuários autenticados podem deletar suas próprias imagens
-- apenas na pasta com seu próprio user_id
CREATE POLICY "Users can delete own game images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'game-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

