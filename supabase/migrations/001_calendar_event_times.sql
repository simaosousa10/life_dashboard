alter table public.calendar_events
  add column if not exists start_time time,
  add column if not exists end_time time,
  add column if not exists location text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'calendar_events_end_requires_start'
  ) then
    alter table public.calendar_events
      add constraint calendar_events_end_requires_start
      check (end_time is null or start_time is not null);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'calendar_events_valid_time_range'
  ) then
    alter table public.calendar_events
      add constraint calendar_events_valid_time_range
      check (end_time is null or end_time > start_time);
  end if;
end $$;

create index if not exists calendar_events_user_date_time_idx
  on public.calendar_events(user_id, event_date, start_time);
