# Life Dashboard

Planner diario pessoal em Flutter para organizar o dia, habitos, saude, estudo e calendario.

## Stack

- Flutter
- Riverpod
- Supabase Auth
- Supabase Postgres com RLS
- Material Design

## Funcionalidades

- Autenticacao por email/password com Supabase.
- Onboarding inicial para criar perfil, objetivos e habitos base.
- Home orientada ao dia com:
  - atividade atual;
  - proximos itens;
  - tarefas de hoje;
  - check-in de habitos;
  - resumo rapido de tarefas, habitos, agua e calorias.
- Calendario com subareas:
  - mes;
  - hoje;
  - tarefas;
  - horario semanal.
- Eventos com data, hora opcional e local opcional.
- Tarefas normais e recorrentes.
- Habitos booleanos, de duracao ou quantidade, com logs diarios.
- Saude com agua, refeicoes, atividades e ecras detalhados por area.
- Notas de estudo com pesquisa e revisao simples.
- Perfil com objetivos, dashboard semanal de habitos e logout.

## Setup Flutter

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

## Setup Supabase

1. Cria um projeto Supabase.
2. Executa `supabase/schema.sql` na base de dados.
3. Aplica migrations em `supabase/migrations/`, se ainda nao estiverem refletidas no schema.
4. Usa apenas a anon key no Flutter. Nunca uses service role key na app cliente.

## Correr a app

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Sem estes `dart-define`, a app mostra um ecrã de configuracao Supabase.

## Estrutura

- `lib/core`: constantes, tema, widgets comuns e erros.
- `lib/data/models`: modelos de dominio.
- `lib/data/repositories`: acesso Supabase por entidade.
- `lib/features`: ecras e widgets por area funcional.
- `lib/providers`: providers Riverpod e agregacoes como o plano diario.
- `supabase/schema.sql`: schema base.
- `supabase/migrations`: migrations incrementais.

## RLS e seguranca

Todas as tabelas com dados do utilizador usam `user_id` e RLS. As policies permitem que cada conta faca `select`, `insert`, `update` e `delete` apenas sobre os seus proprios dados.

A app Flutter usa apenas `SUPABASE_ANON_KEY`. A `service_role key` nao deve ser colocada no codigo, em assets, no README ou em variaveis expostas ao cliente.

## Comandos uteis

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web
```

## Notas de produto

A app esta organizada a volta do dia atual. As perguntas principais sao:

- O que estou a fazer agora?
- O que vem a seguir hoje?
- Que tarefas e habitos tenho de fechar hoje?
- Como correu a minha semana?
- Como estao os meus habitos, saude, estudo e calendario?

## Trabalho futuro

- Excecoes por ocorrencia em tarefas recorrentes.
- Fecho do dia persistido com nota/mood.
- Revisao semanal mais completa.
- Categorias personalizadas.
- Pesquisa global.
- Templates mais completos para rotinas e horario.
