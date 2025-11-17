# Configuração do arquivo .env

## Passo 1: Criar o arquivo .env

Crie um arquivo chamado `.env` na raiz do projeto (mesmo nível do `pubspec.yaml`) com o seguinte conteúdo:

```env
SUPABASE_URL=https://jjgmulwkbkqseqqhbzul.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqZ211bHdrYmtxc2VxcWhienVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMzg4MzIsImV4cCI6MjA3ODkxNDgzMn0.BgwMFZl8-6KSG3Dhj9bGA71htzjO16q5qsB4eWJl2D8
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

