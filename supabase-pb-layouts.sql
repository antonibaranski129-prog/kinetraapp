-- PLYOTIC: sync of Personal bests tile layout between devices.
-- Run once in Supabase SQL Editor (safe to run more than once).
create table if not exists public.pb_layouts (
  user_id uuid not null references auth.users(id) on delete cascade,
  athlete_id uuid not null,
  layout jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, athlete_id)
);
alter table public.pb_layouts enable row level security;
drop policy if exists pb_layouts_own on public.pb_layouts;
create policy pb_layouts_own on public.pb_layouts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
