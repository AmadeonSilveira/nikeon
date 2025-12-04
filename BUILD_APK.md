# Guia para Build de APK - Problema de Login

## Problema Identificado

Ao instalar o APK no dispositivo móvel, o aplicativo não consegue fazer login porque o arquivo `.env` pode não estar sendo carregado corretamente no build de release.

## Soluções Implementadas

### 1. Permissão de Internet Adicionada ✅
- Adicionada a permissão `INTERNET` no `AndroidManifest.xml`
- Necessária para o app conectar ao Supabase

### 2. Tratamento de Erros Melhorado ✅
- Criada tela de erro amigável (`ConfigErrorScreen`)
- Melhorado tratamento de erros no `main.dart`
- O app agora mostra mensagens claras se houver problemas de configuração

### 3. Verificação do Arquivo .env ✅
- O arquivo `.env` está configurado como asset no `pubspec.yaml`
- Verificação de existência e conteúdo antes de inicializar o Supabase

## Como Garantir que o .env está no APK

### Opção 1: Verificar se o arquivo está sendo incluído

1. **Certifique-se que o arquivo `.env` está na raiz do projeto** (mesmo nível do `pubspec.yaml`)

2. **Verifique se está listado no `pubspec.yaml`:**
```yaml
flutter:
  assets:
    - .env
    - assets/images/logo.png
```

3. **Após qualquer alteração no `pubspec.yaml`, execute:**
```bash
flutter clean
flutter pub get
```

4. **Reconstrua o APK:**
```bash
flutter build apk --release
```

### Opção 2: Alternativa - Hardcode das Credenciais (NÃO RECOMENDADO)

**⚠️ ATENÇÃO:** Não recomendado para produção, mas pode ser usado para testes.

Se o problema persistir, você pode temporariamente hardcodar as credenciais diretamente no código:

1. Edite `lib/main.dart` e substitua:
```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
```

Por:
```dart
await Supabase.initialize(
  url: 'https://jjgmulwkbkqseqqhbzul.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqZ211bHdrYmtxc2VxcWhienVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzMzg4MzIsImV4cCI6MjA3ODkxNDgzMn0.BgwMFZl8-6KSG3Dhj9bGA71htzjO16q5qsB4eWJl2D8',
);
```

**⚠️ LEMBRE-SE:** Remova essas credenciais antes de fazer commit no Git!

### Opção 3: Usar build flavors (RECOMENDADO para produção)

Para produção, é melhor usar flavors ou variáveis de ambiente do sistema de build.

## Passos para Testar

1. **Limpe o projeto:**
```bash
flutter clean
```

2. **Reinstale as dependências:**
```bash
flutter pub get
```

3. **Construa o APK de release:**
```bash
flutter build apk --release
```

4. **Instale no dispositivo e teste:**
   - Se aparecer a tela de erro de configuração, o `.env` não está sendo carregado
   - Se aparecer a tela de boas-vindas, o app inicializou corretamente
   - Tente fazer login e verifique se funciona

## Verificação no Dispositivo

Se o app mostrar a tela de erro de configuração ao iniciar, isso significa que:
- O arquivo `.env` não está no APK, OU
- O arquivo está corrompido, OU
- As credenciais estão incorretas

Nesse caso, use a **Opção 2** temporariamente para testar, ou verifique o build novamente.

## Logs para Debug

Se você tiver acesso aos logs do dispositivo (via `adb logcat` ou Flutter DevTools), procure por:
- Mensagens relacionadas ao carregamento do `.env`
- Erros de inicialização do Supabase
- Erros de rede/conexão

## Próximos Passos

1. Tente fazer o build novamente seguindo os passos acima
2. Se o problema persistir, verifique os logs do dispositivo
3. Considere usar flavors para diferentes ambientes (dev/staging/prod)
