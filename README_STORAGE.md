# Configuração do Supabase Storage para Imagens de Jogos

Este documento explica como configurar o Supabase Storage para armazenar imagens de jogos no app Nikeon.

## Passo 1: Criar o Bucket

1. Acesse o [Supabase Dashboard](https://app.supabase.com)
2. Selecione seu projeto
3. Vá em **Storage** no menu lateral
4. Clique em **New bucket**
5. Configure o bucket:
   - **Name**: `game-images`
   - **Public bucket**: **DESMARCADO** (bucket privado)
   - **File size limit**: 5 MB (ou o valor desejado)
   - **Allowed MIME types**: `image/jpeg, image/png, image/webp` (opcional)
6. Clique em **Create bucket**

## Passo 2: Aplicar Políticas RLS

1. No Supabase Dashboard, vá em **SQL Editor**
2. Abra o arquivo `migrations/create_game_images_policy.sql` deste projeto
3. Cole todo o conteúdo SQL no editor
4. Clique em **Run** para executar a query
5. Verifique se as políticas foram criadas em **Storage** → **Policies**

## Estrutura de Pastas

As imagens serão organizadas no seguinte formato:

```
game-images/
└── {user_id}/
    └── games/
        └── {game_id}/
            └── {uuid}.jpg
```

Exemplo:
```
game-images/
└── 123e4567-e89b-12d3-a456-426614174000/
    └── games/
        └── abc123-def456-ghi789/
            └── 987fcdeb-51a2-43c7-8d9e-0f1a2b3c4d5e.jpg
```

## Políticas de Segurança

As políticas criadas garantem que:

1. **Upload**: Usuários autenticados podem fazer upload apenas na pasta com seu próprio `user_id`
2. **Leitura**: Usuários autenticados podem ler todas as imagens do bucket
3. **Atualização**: Usuários autenticados podem atualizar apenas suas próprias imagens
4. **Deleção**: Usuários autenticados podem deletar apenas suas próprias imagens

## URLs Públicas

O Supabase Storage gera URLs públicas para os arquivos. Existem duas opções:

### Opção 1: URLs Públicas (se o bucket for público)
```dart
final url = supabase.storage.from('game-images').getPublicUrl(path);
```

### Opção 2: URLs Assinadas (recomendado para buckets privados)
```dart
final url = supabase.storage.from('game-images').createSignedUrl(path, 3600);
```

**Nota**: O código atual usa `getPublicUrl()`. Se o bucket for privado, você precisará usar URLs assinadas ou tornar o bucket público apenas para leitura.

## Recomendações de Segurança

### ✅ Boas Práticas

1. **Bucket Privado**: Mantenha o bucket privado para maior segurança
2. **Validação de Tamanho**: O código valida tamanho máximo de 5MB no cliente
3. **Validação de Tipo**: Considere validar o tipo MIME no servidor também
4. **RLS Ativado**: Sempre mantenha Row Level Security ativado
5. **Limpeza**: Imagens são deletadas automaticamente quando o jogo é deletado

### ❌ O que NUNCA fazer

1. **Não tornar o bucket público** sem políticas adequadas
2. **Não permitir upload sem autenticação**
3. **Não armazenar imagens muito grandes** (> 5MB)
4. **Não expor service_role key** no cliente
5. **Não permitir upload de arquivos não-imagem**

## Limites Recomendados

- **Tamanho máximo**: 5 MB por imagem
- **Formatos suportados**: JPEG, PNG, WebP
- **Dimensões recomendadas**: 1024x1024 pixels (o código redimensiona automaticamente no mobile)

## Troubleshooting

### Erro: "new row violates row-level security policy"
- Verifique se as políticas RLS foram criadas corretamente
- Certifique-se de que o usuário está autenticado
- Verifique se o caminho do arquivo começa com o `user_id` correto

### Erro: "Bucket not found"
- Verifique se o bucket `game-images` foi criado
- Confirme que o nome está exatamente como `game-images` (case-sensitive)

### Erro: "File too large"
- Verifique o limite de tamanho do bucket (deve ser >= 5MB)
- O código valida 5MB no cliente, mas o Supabase pode ter limites diferentes

### Imagens não aparecem
- Verifique se a URL está correta
- Se o bucket for privado, use URLs assinadas
- Verifique as políticas de leitura

## Testando

1. Crie um jogo no app
2. Selecione uma imagem
3. Salve o jogo
4. Verifique se a imagem aparece em:
   - GamesScreen (thumbnail)
   - GameDetailsScreen (imagem grande)
   - EditGameScreen (preview)

## Próximos Passos

- Implementar compressão de imagens antes do upload
- Adicionar suporte a múltiplas imagens por jogo
- Implementar cache de imagens local
- Adicionar lazy loading para melhor performance

