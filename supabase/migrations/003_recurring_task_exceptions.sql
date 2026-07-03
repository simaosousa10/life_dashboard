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

create index if not exists recurring_task_exceptions_user_date_idx
  on public.recurring_task_exceptions(user_id, date);
create index if not exists recurring_task_exceptions_user_new_due_idx
  on public.recurring_task_exceptions(user_id, new_due_date);

alter table public.recurring_task_exceptions enable row level security;

create policy "recurring_task_exceptions_select_own" on public.recurring_task_exceptions
  for select using (auth.uid() = user_id);
create policy "recurring_task_exceptions_insert_own" on public.recurring_task_exceptions
  for insert with check (auth.uid() = user_id);
create policy "recurring_task_exceptions_update_own" on public.recurring_task_exceptions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "recurring_task_exceptions_delete_own" on public.recurring_task_exceptions
  for delete using (auth.uid() = user_id);
