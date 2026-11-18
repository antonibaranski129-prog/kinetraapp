-- KINETRA sync + coach links. Run once in Supabase SQL Editor (after supabase-profiles.sql).

create table if not exists public.athletes (
  id text primary key,
  user_id uuid unique references auth.users(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete cascade,
  name text, sex text, birth_year int, height_cm numeric, weight_kg numeric,
  updated_at timestamptz not null default now(),
  deleted boolean not null default false
);
create table if not exists public.coach_links (
  coach_id uuid not null references auth.users(id) on delete cascade,
  athlete_id text not null references public.athletes(id) on delete cascade,
  status text not null default 'active' check (status in ('active','revoked')),
  coach_label text,
  created_at timestamptz not null default now(),
  primary key (coach_id, athlete_id)
);
create table if not exists public.results (
  athlete_id text not null references public.athletes(id) on delete cascade,
  id text not null,
  created_by uuid not null references auth.users(id),
  k text, date text,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  synced_at timestamptz not null default now(),
  deleted boolean not null default false,
  primary key (athlete_id, id)
);
create index if not exists results_updated_idx on public.results (updated_at);
create table if not exists public.invites (
  code text primary key,
  athlete_id text not null references public.athletes(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null,
  used_at timestamptz
);

create or replace function public.can_access(aid text) returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.athletes a where a.id = aid
           and (a.user_id = auth.uid() or (a.user_id is null and a.created_by = auth.uid())))
      or exists (select 1 from public.coach_links l where l.athlete_id = aid
           and l.coach_id = auth.uid() and l.status = 'active');
$$;

alter table public.athletes enable row level security;
alter table public.coach_links enable row level security;
alter table public.results enable row level security;
alter table public.invites enable row level security;

create policy "athletes select" on public.athletes for select using (public.can_access(id));
create policy "athletes insert" on public.athletes for insert
  with check (created_by = auth.uid() and (user_id is null or user_id = auth.uid()));
create policy "athletes update" on public.athletes for update
  using (user_id = auth.uid() or (user_id is null and created_by = auth.uid()))
  with check (user_id = auth.uid() or (user_id is null and created_by = auth.uid()));

create policy "results select" on public.results for select using (public.can_access(athlete_id));
create policy "results insert" on public.results for insert
  with check (public.can_access(athlete_id) and created_by = auth.uid());
create policy "results update" on public.results for update
  using (public.can_access(athlete_id)) with check (public.can_access(athlete_id));

create policy "links select" on public.coach_links for select using (
  coach_id = auth.uid() or exists (select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid()));
create policy "links update" on public.coach_links for update using (
  coach_id = auth.uid() or exists (select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid()));
create policy "links delete" on public.coach_links for delete using (
  coach_id = auth.uid() or exists (select 1 from public.athletes a where a.id = athlete_id and a.user_id = auth.uid()));

-- The athlete creates a one-time code (valid 7 days) and gives it to the coach.
create or replace function public.create_invite(p_athlete_id text) returns text
language plpgsql security definer set search_path = public as $$
declare c text;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if not exists (select 1 from public.athletes where id = p_athlete_id and user_id = auth.uid()) then
    raise exception 'not your athlete profile';
  end if;
  c := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  insert into public.invites (code, athlete_id, created_by, expires_at)
    values (c, p_athlete_id, auth.uid(), now() + interval '7 days');
  return c;
end $$;

-- The coach enters the code; the link is created with the athlete's consent (they issued the code).
create or replace function public.redeem_invite(p_code text, p_label text default null) returns text
language plpgsql security definer set search_path = public as $$
declare i public.invites;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into i from public.invites
    where code = upper(trim(p_code)) and used_at is null and expires_at > now();
  if not found then raise exception 'invalid or expired code'; end if;
  if exists (select 1 from public.athletes where id = i.athlete_id and user_id = auth.uid()) then
    raise exception 'you cannot link to yourself';
  end if;
  insert into public.coach_links (coach_id, athlete_id, status, coach_label)
    values (auth.uid(), i.athlete_id, 'active', p_label)
    on conflict (coach_id, athlete_id) do update set status = 'active', coach_label = excluded.coach_label;
  update public.invites set used_at = now() where code = i.code;
  return i.athlete_id;
end $$;

grant execute on function public.create_invite(text) to authenticated;
grant execute on function public.redeem_invite(text, text) to authenticated;
revoke execute on function public.create_invite(text) from anon;
revoke execute on function public.redeem_invite(text, text) from anon;

-- Server arrival time (see supabase-migration-2.sql)
create or replace function public.touch_synced_at() returns trigger
language plpgsql as $$ begin new.synced_at := now(); return new; end $$;
drop trigger if exists results_touch_synced on public.results;
create trigger results_touch_synced before insert or update on public.results
  for each row execute function public.touch_synced_at();
create index if not exists results_synced_idx on public.results (synced_at);
