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

create index if not exists daily_reviews_user_date_idx
  on public.daily_reviews(user_id, date);

alter table public.daily_reviews enable row level security;

create policy "daily_reviews_select_own" on public.daily_reviews
  for select using (auth.uid() = user_id);
create policy "daily_reviews_insert_own" on public.daily_reviews
  for insert with check (auth.uid() = user_id);
create policy "daily_reviews_update_own" on public.daily_reviews
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "daily_reviews_delete_own" on public.daily_reviews
  for delete using (auth.uid() = user_id);
