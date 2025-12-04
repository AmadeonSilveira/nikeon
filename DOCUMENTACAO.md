# Documentação do Projeto Nikeon

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
4. [Sistema de Ranking](#sistema-de-ranking)
5. [Funcionalidades Principais](#funcionalidades-principais)
6. [Fluxo de Dados](#fluxo-de-dados)
7. [Segurança e Permissões](#segurança-e-permissões)
8. [Estrutura do Código](#estrutura-do-código)

---

## 🎯 Visão Geral

**Nikeon** (anteriormente Arkion) é um aplicativo Flutter desenvolvido para gerenciar jogos de tabuleiro, registrar partidas e manter rankings competitivos entre jogadores. O sistema permite que usuários cadastrem jogos, registrem partidas com múltiplos participantes e acompanhem estatísticas e rankings globais e por jogo.

### Tecnologias Utilizadas

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Autenticação**: Supabase Auth
- **Banco de Dados**: PostgreSQL com Row Level Security (RLS)
- **Armazenamento**: Supabase Storage (para imagens de jogos)

---

## 🏗️ Arquitetura do Sistema

O projeto segue uma arquitetura em camadas:

```
┌─────────────────────────────────────┐
│         Flutter App (UI)            │
│  (Screens, Components, Widgets)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Services Layer                  │
│  (Auth, Game, Match, Ranking)        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Models Layer                    │
│  (Game, Match, Player, Ranking)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Supabase Client              │
│  (API, Auth, Storage)                │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      PostgreSQL Database             │
│  (Tables, Triggers, RLS Policies)    │
└──────────────────────────────────────┘
```

### Camadas Principais

1. **UI Layer** (`lib/screens/`, `lib/components/`): Telas e componentes visuais
2. **Services Layer** (`lib/services/`): Lógica de negócio e comunicação com Supabase
3. **Models Layer** (`lib/models/`): Modelos de dados
4. **Database Layer**: Tabelas, triggers e políticas RLS no PostgreSQL

---

## 🗄️ Estrutura do Banco de Dados

### Tabelas Principais

#### 1. `profiles`
Armazena informações adicionais dos usuários além dos dados de autenticação.

```sql
- id (UUID, PK, FK → auth.users)
- name (TEXT)
- email (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

**Características**:
- Criada automaticamente quando um usuário se cadastra
- Atualização automática de `updated_at` via trigger
- RLS: Usuários só podem ver/editar seu próprio perfil

#### 2. `games`
Armazena jogos cadastrados pelos usuários, incluindo jogos base e expansões.

```sql
- id (UUID, PK)
- user_id (UUID, FK → auth.users)
- name (TEXT)
- description (TEXT, opcional)
- min_players (SMALLINT, opcional)
- max_players (SMALLINT, opcional)
- play_time_minutes (INTEGER, opcional)
- image_url (TEXT, opcional)
- parent_game_id (UUID, FK → games.id, opcional)
- scoring_config (JSONB, opcional)
- created_at (TIMESTAMP)
```

**Características**:
- Suporta hierarquia de jogos (jogos base e expansões via `parent_game_id`)
- Configuração de pontuação personalizada por jogo (`scoring_config`)
- RLS: Qualquer usuário autenticado pode visualizar, apenas o criador pode editar/deletar
- Imagens armazenadas no Supabase Storage

#### 3. `matches`
Armazena partidas jogadas pelos usuários.

```sql
- id (UUID, PK)
- user_id (UUID, FK → auth.users)
- game_id (UUID, FK → games.id, opcional)
- game_name (TEXT)
- result (ENUM: 'win' | 'loss')
- played_at (TIMESTAMP)
- created_at (TIMESTAMP)
```

**Características**:
- `game_name` é obrigatório (backup de compatibilidade)
- `game_id` é opcional (pode ser null se o jogo não estiver cadastrado)
- `result` indica se o dono da partida venceu ou perdeu
- RLS: Usuários só podem ver/editar suas próprias partidas
- Triggers automáticos atualizam o ranking ao inserir partidas

#### 4. `match_participants`
Armazena os participantes de cada partida (jogadores registrados e convidados).

```sql
- id (UUID, PK)
- match_id (UUID, FK → matches.id)
- user_id (UUID, FK → auth.users, opcional)
- name (TEXT)
- is_winner (BOOLEAN)
- score (INTEGER, opcional)
- created_at (TIMESTAMP)
```

**Características**:
- Suporta jogadores registrados (`user_id` não nulo) e convidados (`user_id` nulo)
- `is_winner` indica se o participante venceu
- `score` permite pontuação personalizada por participante
- RLS: Usuários só podem ver/editar participantes de suas próprias partidas
- Triggers automáticos atualizam o ranking para TODOS os participantes vencedores

#### 5. `leaderboard` (Ranking Global)
Ranking consolidado por usuário, atualizado automaticamente.

```sql
- user_id (UUID, PK, FK → auth.users)
- score (INTEGER)
- wins (INTEGER)
- losses (INTEGER)
- matches (INTEGER)
```

**Características**:
- Atualizado automaticamente via triggers
- RLS: Qualquer usuário autenticado pode visualizar
- Apenas triggers podem inserir/atualizar (sem políticas de INSERT/UPDATE)

#### 6. `leaderboard_by_game` (Ranking por Jogo)
Ranking específico por jogo, atualizado automaticamente.

```sql
- user_id (UUID, FK → auth.users)
- game_id (UUID, FK → games.id)
- score (INTEGER)
- wins (INTEGER)
- losses (INTEGER)
- matches (INTEGER)
- PRIMARY KEY (user_id, game_id)
```

**Características**:
- Ranking separado para cada jogo
- Atualizado automaticamente via triggers
- RLS: Qualquer usuário autenticado pode visualizar
- Apenas triggers podem inserir/atualizar

---

## 🏆 Sistema de Ranking

### Lógica de Pontuação

O sistema de ranking funciona em duas camadas:

1. **Ranking Global**: Consolida todas as partidas de todos os jogos
2. **Ranking por Jogo**: Ranking específico para cada jogo cadastrado

### Fórmula de Pontuação

**Regra Padrão**:
```
score = vitórias × 3
```

**Pontuação Personalizada**:
- Se um participante vencedor tiver `score` informado na tabela `match_participants`, usa essa pontuação
- Caso contrário, usa a fórmula padrão (3 pontos por vitória)

### Atualização Automática

O ranking é atualizado automaticamente através de **triggers SQL** que são disparados quando:

1. **Uma partida é inserida** (`matches`):
   - Se a partida **não tiver participantes**, atualiza apenas o dono da partida baseado no campo `result`
   - Se a partida **tiver participantes**, os triggers de `match_participants` fazem a atualização

2. **Um participante é inserido/atualizado** (`match_participants`):
   - **Participante Vencedor** (`is_winner = true`):
     - Atualiza ranking global e por jogo para TODOS os participantes vencedores
     - Usa `score` do participante se disponível, senão usa 3 pontos
   - **Participante Perdedor** (`is_winner = false`):
     - Incrementa apenas `losses` e `matches`
     - Não adiciona pontos ao `score`

### Funções SQL Principais

#### `handle_participant_winner_ranking()`
Atualiza o ranking quando um participante vencedor é inserido/atualizado.

**Lógica**:
- Verifica se o participante é vencedor e tem `user_id` (não é convidado)
- Busca informações da partida
- Calcula incremento de score (usa `score` do participante ou 3 pontos padrão)
- Atualiza `leaderboard` (ranking global)
- Atualiza `leaderboard_by_game` (ranking por jogo)
- Se o participante for o dono da partida, ajusta o que foi feito pelo trigger de `matches`

#### `handle_participant_loser_ranking()`
Atualiza o ranking quando um participante perdedor é inserido/atualizado.

**Lógica**:
- Verifica se o participante não é vencedor e tem `user_id`
- Incrementa apenas `losses` e `matches` (não adiciona pontos)
- Se não for o dono da partida, adiciona normalmente

#### `handle_leaderboard_update()`
Atualiza o ranking global quando uma partida é inserida (apenas se não houver participantes).

**Lógica**:
- Verifica se há participantes para a partida
- Se houver participantes, retorna (os triggers de participantes fazem a atualização)
- Se não houver, usa a lógica antiga (compatibilidade com partidas antigas)

#### `handle_leaderboard_by_game_update()`
Atualiza o ranking por jogo quando uma partida é inserida (apenas se não houver participantes).

**Lógica**:
- Similar a `handle_leaderboard_update()`, mas para ranking por jogo
- Busca o `game_id` pelo nome do jogo

### Views

#### `leaderboard_view`
View que faz JOIN entre `leaderboard` e `profiles` para incluir o nome do usuário.

#### `leaderboard_by_game_view`
View que faz JOIN entre `leaderboard_by_game` e `profiles` para incluir o nome do usuário.

---

## ⚙️ Funcionalidades Principais

### 1. Autenticação

- **Cadastro de Usuário**: Criação de conta com email e senha
- **Login**: Autenticação com email e senha
- **Logout**: Encerramento de sessão
- **Verificação de Email**: Verifica se um email já está cadastrado (sem expor dados)

**Serviço**: `AuthService` (`lib/services/auth_service.dart`)

### 2. Gerenciamento de Jogos

- **Cadastro de Jogos**: Criar jogos base com informações detalhadas
- **Expansões**: Cadastrar expansões vinculadas a jogos base
- **Edição**: Editar informações de jogos próprios
- **Exclusão**: Deletar jogos próprios (expansões são deletadas em cascata)
- **Upload de Imagens**: Enviar imagens para Supabase Storage
- **Visibilidade Global**: Todos os usuários autenticados podem ver todos os jogos

**Serviço**: `GameService` (`lib/services/game_service.dart`)

### 3. Registro de Partidas

- **Criar Partida**: Registrar uma nova partida com:
  - Nome do jogo
  - Data/hora da partida
  - Lista de participantes (jogadores registrados e convidados)
  - Indicação de vencedores
  - Pontuação opcional por participante
- **Visualizar Partidas**: Ver histórico de partidas jogadas
- **Estatísticas**: Ver total de partidas, vitórias e derrotas
- **Edição/Exclusão**: Editar ou deletar partidas próprias

**Serviço**: `MatchService` (`lib/services/match_service.dart`)

### 4. Sistema de Ranking

- **Ranking Global**: Visualizar ranking geral de todos os jogadores
- **Ranking por Jogo**: Visualizar ranking específico de um jogo
- **Estatísticas Pessoais**: Ver posição e estatísticas do usuário logado
- **Atualização Automática**: Ranking atualizado automaticamente ao registrar partidas

**Serviço**: `RankingService` (`lib/services/ranking_service.dart`)

### 5. Participantes de Partidas

- **Jogadores Registrados**: Adicionar usuários cadastrados como participantes
- **Convidados**: Adicionar jogadores não cadastrados (apenas nome)
- **Múltiplos Vencedores**: Suporta partidas com múltiplos vencedores
- **Pontuação Personalizada**: Atribuir pontuação específica a cada participante

---

## 🔄 Fluxo de Dados

### Fluxo de Criação de Partida

```
1. Usuário preenche formulário de partida
   ↓
2. MatchService.createMatch() é chamado
   ↓
3. Calcula resultado baseado nos participantes vencedores
   ↓
4. Insere registro em 'matches'
   ↓
5. Trigger handle_leaderboard_update() é disparado
   ↓
6. Trigger handle_leaderboard_by_game_update() é disparado
   ↓
7. Insere participantes em 'match_participants'
   ↓
8. Para cada participante vencedor:
   - Trigger handle_participant_winner_ranking() é disparado
   - Atualiza ranking global e por jogo
   ↓
9. Para cada participante perdedor:
   - Trigger handle_participant_loser_ranking() é disparado
   - Incrementa losses e matches
```

### Fluxo de Consulta de Ranking

```
1. Usuário acessa tela de ranking
   ↓
2. RankingService.getGlobalRanking() ou getGameRanking() é chamado
   ↓
3. Consulta view 'leaderboard_view' ou 'leaderboard_by_game_view'
   ↓
4. View faz JOIN com 'profiles' para incluir nomes
   ↓
5. Retorna lista ordenada por score (descendente)
   ↓
6. UI exibe ranking com posições calculadas
```

### Fluxo de Autenticação

```
1. Usuário faz login/cadastro
   ↓
2. AuthService.signIn() ou signUp() é chamado
   ↓
3. Supabase Auth autentica/cria usuário
   ↓
4. Se cadastro: cria perfil em 'profiles'
   ↓
5. Sessão é mantida no Supabase Client
   ↓
6. App verifica autenticação em cada requisição
```

---

## 🔒 Segurança e Permissões

### Row Level Security (RLS)

Todas as tabelas principais possuem RLS ativado para garantir segurança:

#### `profiles`
- **SELECT**: Usuários podem ver apenas seu próprio perfil
- **INSERT**: Usuários podem inserir apenas seu próprio perfil
- **UPDATE**: Usuários podem atualizar apenas seu próprio perfil

#### `games`
- **SELECT**: Qualquer usuário autenticado pode ver todos os jogos
- **INSERT**: Usuários podem inserir apenas jogos com seu próprio `user_id`
- **UPDATE**: Apenas o criador pode editar
- **DELETE**: Apenas o criador pode deletar

#### `matches`
- **SELECT**: Usuários podem ver apenas suas próprias partidas
- **INSERT**: Usuários podem inserir apenas partidas com seu próprio `user_id`
- **UPDATE**: Apenas o dono pode editar
- **DELETE**: Apenas o dono pode deletar

#### `match_participants`
- **SELECT**: Usuários podem ver participantes apenas de suas próprias partidas
- **INSERT**: Usuários podem inserir participantes apenas em suas próprias partidas
- **UPDATE**: Apenas o dono da partida pode editar
- **DELETE**: Apenas o dono da partida pode deletar

#### `leaderboard` e `leaderboard_by_game`
- **SELECT**: Qualquer usuário autenticado pode ver o ranking completo
- **INSERT/UPDATE/DELETE**: Apenas triggers podem modificar (sem políticas de usuário)

### Funções com SECURITY DEFINER

As funções de trigger são criadas com `SECURITY DEFINER` para contornar RLS e permitir atualizações automáticas do ranking, mesmo quando executadas por triggers.

### Autenticação

- Credenciais do Supabase armazenadas em `.env` (não commitado)
- Uso apenas da chave "anon" (anon public key) no cliente
- Chave "service_role" nunca usada no cliente (apenas no backend se necessário)

---

## 📁 Estrutura do Código

### Diretórios Principais

```
lib/
├── components/          # Componentes reutilizáveis
│   ├── game_card.dart
│   ├── match_tile.dart
│   ├── participant_manager.dart
│   └── ...
├── config/             # Configurações
│   └── env.dart        # Variáveis de ambiente
├── helpers/            # Funções auxiliares
├── models/             # Modelos de dados
│   ├── game.dart
│   ├── match.dart
│   ├── match_participant.dart
│   ├── player.dart
│   └── ranking_entry.dart
├── screens/            # Telas da aplicação
│   ├── home_screen.dart
│   ├── games_screen.dart
│   ├── ranking_screen.dart
│   ├── register_match_screen.dart
│   └── ...
├── services/           # Serviços de negócio
│   ├── auth_service.dart
│   ├── game_service.dart
│   ├── match_service.dart
│   ├── player_service.dart
│   └── ranking_service.dart
├── theme/              # Tema da aplicação
│   └── neon_theme.dart
├── widgets/            # Widgets customizados
│   ├── neon_bottom_nav_bar.dart
│   └── neon_fab.dart
└── main.dart           # Ponto de entrada

migrations/             # Migrações SQL do banco de dados
├── 001_profiles.sql
├── 002_games.sql
├── 003_matches.sql
├── 004_ranking.sql
├── ...
└── 014_update_all_winners_ranking.sql
```

### Padrões de Código

1. **Services**: Abstraem comunicação com Supabase
2. **Models**: Representam entidades do domínio
3. **Screens**: Telas principais da aplicação
4. **Components**: Componentes reutilizáveis de UI
5. **Migrations**: Scripts SQL idempotentes para evolução do banco

---

## 📝 Observações Importantes

### Compatibilidade com Partidas Antigas

O sistema mantém compatibilidade com partidas antigas que não possuem participantes:
- Se uma partida não tiver participantes, os triggers de `matches` atualizam o ranking baseado no campo `result`
- Se uma partida tiver participantes, os triggers de `match_participants` fazem a atualização

### Múltiplos Vencedores

O sistema suporta partidas com múltiplos vencedores:
- Cada participante vencedor é processado individualmente pelos triggers
- Todos os vencedores recebem pontos no ranking
- O campo `result` da partida indica apenas se o **dono da partida** venceu

### Pontuação Personalizada

- Cada participante pode ter uma pontuação específica (`score` em `match_participants`)
- Se não informada, usa a fórmula padrão (3 pontos por vitória)
- A pontuação personalizada é usada apenas para vencedores

### Performance

- Índices criados nas tabelas principais para otimizar consultas
- Views materializadas podem ser criadas no futuro se necessário
- Triggers são executados de forma eficiente no banco de dados

---

## 🚀 Próximos Passos

Possíveis melhorias futuras:

1. **Sistema de Amizades**: Adicionar relacionamento entre usuários
2. **Notificações**: Notificar usuários sobre partidas e rankings
3. **Estatísticas Avançadas**: Gráficos e análises mais detalhadas
4. **Modo Offline**: Suporte para uso offline com sincronização
5. **Exportação de Dados**: Exportar estatísticas em PDF/CSV
6. **Sistema de Torneios**: Organizar torneios e competições

---

## 📚 Referências

- [Documentação do Flutter](https://flutter.dev/docs)
- [Documentação do Supabase](https://supabase.com/docs)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/triggers.html)
- [Row Level Security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

---

**Última atualização**: Dezembro 2024

