# Configuração do arquivo .env

## Passo 1: Criar o arquivo .env

Crie um arquivo chamado `.env` na raiz do projeto (mesmo nível do `pubspec.yaml`) com o seguinte conteúdo:

```env
SUPABASE_URL=supabase_url
SUPABASE_ANON_KEY=anon_key
```

**IMPORTANTE:** Substitua os valores acima pelas suas credenciais reais do Supabase se ainda não foram configuradas.

## Segurança

### ✅ Use apenas a chave "anon" (anon public key)
- A chave anon é segura para uso no cliente
- Ela respeita as políticas de Row Level Security (RLS) do banco de dados
- Está disponível publicamente no dashboard do Supabase

### ❌ NUNCA use a chave "service_role"
- A chave service_role tem permissões totais no banco de dados
- Ela ignora todas as políticas de segurança (RLS)
- Deve ser usada APENAS em ambientes de servidor seguros
- NUNCA deve ser incluída em código cliente ou commitada

### 🔒 Proteção do arquivo .env
- O arquivo `.env` está no `.gitignore` e não será commitado
- Mantenha suas credenciais privadas
- Não compartilhe o arquivo `.env` publicamente

## Verificação

Após criar o arquivo `.env`, execute:

```bash
flutter pub get
flutter run
```

O app deve inicializar corretamente com as credenciais do arquivo `.env`.

