alter table public.study_notes
  add column if not exists needs_review boolean not null default false,
  add column if not exists next_review_date date,
  add column if not exists difficulty text;

create index if not exists study_notes_user_review_idx
  on public.study_notes(user_id, needs_review, next_review_date);
