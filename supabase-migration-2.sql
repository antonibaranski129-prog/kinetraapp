-- PLYOTIC migration 2: server-side arrival time for reliable multi-device sync.
-- Run once in Supabase SQL Editor (safe to run more than once).
alter table public.results add column if not exists synced_at timestamptz not null default now();
create or replace function public.touch_synced_at() returns trigger
language plpgsql as $$ begin new.synced_at := now(); return new; end $$;
drop trigger if exists results_touch_synced on public.results;
create trigger results_touch_synced before insert or update on public.results
  for each row execute function public.touch_synced_at();
create index if not exists results_synced_idx on public.results (synced_at);
