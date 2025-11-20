# Guia de Configuração do Ranking Global

Este documento explica como as novas tabelas de ranking funcionam,
como os gatilhos são disparados e como você pode personalizar o cálculo
da pontuação no futuro.

---

## Visão geral

Foram criadas duas tabelas:

1. `leaderboard` — ranking global consolidado por usuário.
2. `leaderboard_by_game` — ranking específico por jogo (combinação usuário + jogo).

Cada vez que uma partida é registrada na tabela `matches`, dois gatilhos
SQL atualizam automaticamente as tabelas acima, mantendo o ranking sempre
sincronizado.

---

## Como os gatilhos funcionam

1. **Trigger `trg_matches_leaderboard`**  
   - Disparado `AFTER INSERT` em `matches`.
   - Chama a função `handle_leaderboard_update`.
   - Incrementa vitórias/derrotas, número de partidas e recalcula o score global.

2. **Trigger `trg_matches_leaderboard_by_game`**  
   - Também `AFTER INSERT` em `matches`.
   - Chama a função `handle_leaderboard_by_game_update`.
   - Procura o `game_id` correspondente (com base no nome do jogo) e
     atualiza o ranking daquele jogo.
   - Se o jogo não estiver cadastrado na tabela `games`, o trigger ignora
     o registro (não há ranking por jogo nesse caso).

Ambas as funções foram criadas com `SECURITY DEFINER`, garantindo que
os updates aconteçam mesmo com RLS ativado nas tabelas de ranking.

---

## Consulta manual

Você pode inspecionar os rankings diretamente no SQL Editor do Supabase:

```sql
-- Ranking global (ordenado por score)
SELECT *
FROM public.leaderboard
ORDER BY score DESC;

-- Ranking por jogo específico
SELECT lb.*, g.name AS game_name
FROM public.leaderboard_by_game lb
JOIN public.games g ON g.id = lb.game_id
WHERE lb.game_id = 'UUID_DO_JOGO'
ORDER BY lb.score DESC;
```

As políticas RLS permitem `SELECT` para qualquer usuário autenticado,
por isso as mesmas consultas podem ser feitas pelo cliente Flutter
através do `RankingService`.

---

## Fórmula de pontuação

A regra inicial definida foi:

```
score = vitórias * 3
```

Esta regra está implementada em dois lugares:

1. Nas funções SQL (`handle_leaderboard_update` e `handle_leaderboard_by_game_update`).
2. No helper `calculateScore` do `RankingService` (para manter consistência
   ao exibir ou recalcular valores no cliente).

### Alterando a fórmula

Caso deseje mudar a fórmula no futuro:

1. Edite o cálculo em ambas as funções SQL (score_increment).
2. Atualize o método `calculateScore` no `RankingService`.
3. (Opcional) Rode um script para recalcular os scores históricos
   reprocessando a tabela `matches`.

---

## Reprocessando o ranking

Se for necessário recalcular o ranking do zero (por exemplo, após atualizar
a fórmula), execute o seguinte procedimento:

1. **Zere as tabelas de ranking:**
   ```sql
   TRUNCATE TABLE public.leaderboard;
   TRUNCATE TABLE public.leaderboard_by_game;
   ```
2. **Reinsira os dados percorrendo todas as partidas:**
   ```sql
   DO $$
   DECLARE
     match_record RECORD;
   BEGIN
     FOR match_record IN SELECT * FROM public.matches ORDER BY played_at ASC LOOP
       PERFORM public.handle_leaderboard_update();
       PERFORM public.handle_leaderboard_by_game_update();
     END LOOP;
   END;
   $$;
   ```
   *(A função pode ser adaptada para passar os valores necessários, caso deseje
   reaproveitar os gatilhos diretamente.)*

---

## Segurança e RLS

- As tabelas de ranking possuem RLS ativado.
- Apenas `SELECT` está liberado (`USING (true)`), permitindo que qualquer usuário
  autenticado veja o ranking completo.
- Não há políticas de `INSERT/UPDATE/DELETE`; logo, apenas as funções executadas
  pelos gatilhos conseguem alterar os dados.

---

## Integração com o Flutter

- Use o `RankingService` (`lib/services/ranking_service.dart`) para consultar
  o ranking dentro do app.
- O serviço expõe métodos para:
  - Ranking global (`getGlobalRanking`).
  - Ranking por jogo (`getGameRanking`).
  - Estatísticas do usuário (`getUserGlobalStats` e `getUserGameStats`).

---

## Próximos passos

- Criar as telas de UI que consumirão o `RankingService`.
- Permitir filtros e métricas adicionais (por exemplo: taxa de vitória,
  streaks, etc).
- Adicionar botões de reprocessamento ou atualizações de fórmula via painéis
  administrativos.

---

Qualquer alteração futura no ranking deve manter a consistência entre:
1. Funções SQL (backend).
2. Serviço de ranking no Flutter (frontend).

Assim garantimos que o app e o banco falem a mesma língua sobre pontuação
e posições no leaderboard.





