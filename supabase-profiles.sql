create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  sex text check (sex in ('Male','Female','Prefer not to specify')),
  birth_year int check (birth_year between 1900 and 2100),
  height_cm numeric(4,1) check (height_cm between 120 and 230),
  weight_kg numeric(4,1) check (weight_kg between 30 and 250),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "profiles select own" on public.profiles for select using (user_id = auth.uid());
create policy "profiles insert own" on public.profiles for insert with check (user_id = auth.uid());
create policy "profiles update own" on public.profiles for update using (user_id = auth.uid()) with check (user_id = auth.uid());
