create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text not null,
  weight_kg numeric(6, 2) not null default 70 check (weight_kg > 0),
  daily_water_goal_ml integer not null default 2000 check (daily_water_goal_ml > 0),
  daily_calorie_goal integer not null default 2200 check (daily_calorie_goal > 0),
  onboarding_completed boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  color text,
  icon text,
  created_at timestamptz not null default now(),
  constraint categories_user_name_key unique (user_id, name)
);

create table if not exists public.schedule_blocks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  weekday integer not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  category text not null,
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);

create table if not exists public.recurring_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  weekdays integer[] not null check (array_length(weekdays, 1) > 0),
  time time,
  start_date date not null default current_date,
  end_date date,
  priority text not null default 'normal' check (priority in ('baixa', 'normal', 'alta')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (id, user_id),
  check (end_date is null or end_date >= start_date)
);

create table if not exists public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recurring_task_id uuid,
  title text not null,
  description text,
  due_date date,
  due_time time,
  priority text not null default 'normal' check (priority in ('baixa', 'normal', 'alta')),
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  constraint todos_recurring_task_user_fkey
    foreign key (recurring_task_id, user_id)
    references public.recurring_tasks(id, user_id)
    on delete cascade,
  constraint todos_recurring_task_requires_due_date
    check (recurring_task_id is null or due_date is not null),
  constraint todos_unique_recurring_occurrence
    unique (user_id, recurring_task_id, due_date)
);

create table if not exists public.recurring_task_exceptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  recurring_task_id uuid not null references public.recurring_tasks(id) on delete cascade,
  date date not null,
  exception_type text not null check (exception_type in ('skip', 'reschedule', 'modified')),
  new_due_date date,
  new_time time,
  created_at timestamptz not null default now(),
  constraint recurring_task_exceptions_unique_day
    unique (user_id, recurring_task_id, date),
  check (exception_type <> 'reschedule' or new_due_date is not null)
);

create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  category text,
  target_type text not null check (target_type in ('boolean', 'duration', 'quantity')),
  target_value numeric,
  target_unit text,
  weekdays integer[] not null default '{}',
  start_date date not null default current_date,
  end_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (id, user_id),
  check (array_length(weekdays, 1) > 0),
  check (end_date is null or end_date >= start_date)
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null references public.habits(id) on delete cascade,
  date date not null,
  is_completed boolean not null default false,
  value numeric,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint habit_logs_habit_user_fkey
    foreign key (habit_id, user_id)
    references public.habits(id, user_id)
    on delete cascade,
  constraint habit_logs_unique_day
    unique (user_id, habit_id, date)
);

create table if not exists public.study_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  subject text not null,
  needs_review boolean not null default false,
  next_review_date date,
  difficulty text,
  created_at timestamptz not null default now()
);

create table if not exists public.water_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_ml integer not null check (amount_ml > 0),
  date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  event_date date not null,
  start_time time,
  end_time time,
  category text not null,
  location text,
  created_at timestamptz not null default now(),
  check (end_time is null or start_time is not null),
  check (end_time is null or end_time > start_time)
);

create table if not exists public.meal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meal_name text not null,
  calories integer not null check (calories > 0),
  protein_g numeric(7, 2) not null default 0 check (protein_g >= 0),
  carbs_g numeric(7, 2) not null default 0 check (carbs_g >= 0),
  fat_g numeric(7, 2) not null default 0 check (fat_g >= 0),
  date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.activity_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  activity_name text not null,
  duration_minutes integer not null check (duration_minutes > 0),
  met numeric(6, 2) not null check (met > 0),
  weight_kg numeric(6, 2) not null check (weight_kg > 0),
  calories_burned numeric(8, 2) not null check (calories_burned >= 0),
  date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  note text,
  mood integer check (mood between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_reviews_unique_day unique (user_id, date)
);

create index if not exists profiles_user_id_idx on public.profiles(user_id);
create index if not exists categories_user_name_idx on public.categories(user_id, name);
create index if not exists schedule_blocks_user_weekday_idx on public.schedule_blocks(user_id, weekday, start_time);
create index if not exists recurring_tasks_user_active_idx on public.recurring_tasks(user_id, is_active, start_date);
create index if not exists recurring_task_exceptions_user_date_idx on public.recurring_task_exceptions(user_id, date);
create index if not exists recurring_task_exceptions_user_new_due_idx on public.recurring_task_exceptions(user_id, new_due_date);
create index if not exists todos_user_due_idx on public.todos(user_id, is_completed, due_date);
create index if not exists todos_user_due_time_idx on public.todos(user_id, due_date, due_time);
create index if not exists habits_user_active_idx on public.habits(user_id, is_active, start_date);
create index if not exists habit_logs_user_date_idx on public.habit_logs(user_id, date);
create index if not exists habit_logs_user_habit_date_idx on public.habit_logs(user_id, habit_id, date);
create index if not exists study_notes_user_created_idx on public.study_notes(user_id, created_at desc);
create index if not exists water_entries_user_date_idx on public.water_entries(user_id, date);
create index if not exists calendar_events_user_date_idx on public.calendar_events(user_id, event_date);
create index if not exists meal_entries_user_date_idx on public.meal_entries(user_id, date);
create index if not exists activity_entries_user_date_idx on public.activity_entries(user_id, date);
create index if not exists daily_reviews_user_date_idx on public.daily_reviews(user_id, date);

alter table public.todos add column if not exists recurring_task_id uuid;
alter table public.todos add column if not exists due_time time;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'recurring_tasks_id_user_id_key'
  ) then
    alter table public.recurring_tasks
      add constraint recurring_tasks_id_user_id_key unique (id, user_id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'todos_recurring_task_user_fkey'
  ) then
    alter table public.todos
      add constraint todos_recurring_task_user_fkey
      foreign key (recurring_task_id, user_id)
      references public.recurring_tasks(id, user_id)
      on delete cascade;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'todos_recurring_task_requires_due_date'
  ) then
    alter table public.todos
      add constraint todos_recurring_task_requires_due_date
      check (recurring_task_id is null or due_date is not null);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'todos_unique_recurring_occurrence'
  ) then
    alter table public.todos
      add constraint todos_unique_recurring_occurrence
      unique (user_id, recurring_task_id, due_date);
  end if;
end $$;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.schedule_blocks enable row level security;
alter table public.recurring_tasks enable row level security;
alter table public.recurring_task_exceptions enable row level security;
alter table public.todos enable row level security;
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;
alter table public.study_notes enable row level security;
alter table public.water_entries enable row level security;
alter table public.calendar_events enable row level security;
alter table public.meal_entries enable row level security;
alter table public.activity_entries enable row level security;
alter table public.daily_reviews enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = user_id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = user_id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "profiles_delete_own" on public.profiles
  for delete using (auth.uid() = user_id);

create policy "categories_select_own" on public.categories
  for select using (auth.uid() = user_id);
create policy "categories_insert_own" on public.categories
  for insert with check (auth.uid() = user_id);
create policy "categories_update_own" on public.categories
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "categories_delete_own" on public.categories
  for delete using (auth.uid() = user_id);

create policy "schedule_blocks_select_own" on public.schedule_blocks
  for select using (auth.uid() = user_id);
create policy "schedule_blocks_insert_own" on public.schedule_blocks
  for insert with check (auth.uid() = user_id);
create policy "schedule_blocks_update_own" on public.schedule_blocks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "schedule_blocks_delete_own" on public.schedule_blocks
  for delete using (auth.uid() = user_id);

create policy "recurring_tasks_select_own" on public.recurring_tasks
  for select using (auth.uid() = user_id);
create policy "recurring_tasks_insert_own" on public.recurring_tasks
  for insert with check (auth.uid() = user_id);
create policy "recurring_tasks_update_own" on public.recurring_tasks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "recurring_tasks_delete_own" on public.recurring_tasks
  for delete using (auth.uid() = user_id);

create policy "recurring_task_exceptions_select_own" on public.recurring_task_exceptions
  for select using (auth.uid() = user_id);
create policy "recurring_task_exceptions_insert_own" on public.recurring_task_exceptions
  for insert with check (auth.uid() = user_id);
create policy "recurring_task_exceptions_update_own" on public.recurring_task_exceptions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "recurring_task_exceptions_delete_own" on public.recurring_task_exceptions
  for delete using (auth.uid() = user_id);

create policy "todos_select_own" on public.todos
  for select using (auth.uid() = user_id);
create policy "todos_insert_own" on public.todos
  for insert with check (auth.uid() = user_id);
create policy "todos_update_own" on public.todos
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "todos_delete_own" on public.todos
  for delete using (auth.uid() = user_id);

create policy "habits_select_own" on public.habits
  for select using (auth.uid() = user_id);
create policy "habits_insert_own" on public.habits
  for insert with check (auth.uid() = user_id);
create policy "habits_update_own" on public.habits
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "habits_delete_own" on public.habits
  for delete using (auth.uid() = user_id);

create policy "habit_logs_select_own" on public.habit_logs
  for select using (auth.uid() = user_id);
create policy "habit_logs_insert_own" on public.habit_logs
  for insert with check (auth.uid() = user_id);
create policy "habit_logs_update_own" on public.habit_logs
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "habit_logs_delete_own" on public.habit_logs
  for delete using (auth.uid() = user_id);

create policy "study_notes_select_own" on public.study_notes
  for select using (auth.uid() = user_id);
create policy "study_notes_insert_own" on public.study_notes
  for insert with check (auth.uid() = user_id);
create policy "study_notes_update_own" on public.study_notes
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "study_notes_delete_own" on public.study_notes
  for delete using (auth.uid() = user_id);

create policy "water_entries_select_own" on public.water_entries
  for select using (auth.uid() = user_id);
create policy "water_entries_insert_own" on public.water_entries
  for insert with check (auth.uid() = user_id);
create policy "water_entries_update_own" on public.water_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "water_entries_delete_own" on public.water_entries
  for delete using (auth.uid() = user_id);

create policy "calendar_events_select_own" on public.calendar_events
  for select using (auth.uid() = user_id);
create policy "calendar_events_insert_own" on public.calendar_events
  for insert with check (auth.uid() = user_id);
create policy "calendar_events_update_own" on public.calendar_events
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "calendar_events_delete_own" on public.calendar_events
  for delete using (auth.uid() = user_id);

create policy "meal_entries_select_own" on public.meal_entries
  for select using (auth.uid() = user_id);
create policy "meal_entries_insert_own" on public.meal_entries
  for insert with check (auth.uid() = user_id);
create policy "meal_entries_update_own" on public.meal_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "meal_entries_delete_own" on public.meal_entries
  for delete using (auth.uid() = user_id);

create policy "activity_entries_select_own" on public.activity_entries
  for select using (auth.uid() = user_id);
create policy "activity_entries_insert_own" on public.activity_entries
  for insert with check (auth.uid() = user_id);
create policy "activity_entries_update_own" on public.activity_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "activity_entries_delete_own" on public.activity_entries
  for delete using (auth.uid() = user_id);

create policy "daily_reviews_select_own" on public.daily_reviews
  for select using (auth.uid() = user_id);
create policy "daily_reviews_insert_own" on public.daily_reviews
  for insert with check (auth.uid() = user_id);
create policy "daily_reviews_update_own" on public.daily_reviews
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "daily_reviews_delete_own" on public.daily_reviews
  for delete using (auth.uid() = user_id);
