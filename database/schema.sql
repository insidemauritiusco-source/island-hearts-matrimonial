-- Island Hearts isolated backend foundation. Run ONLY in a dedicated Supabase project.
-- Authentication managed by Supabase Auth. Never expose service_role key in frontend.
create table if not exists public.ih_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 60),
  age integer not null check (age between 18 and 110),
  gender text not null check (gender in ('woman','man','other')),
  city text not null check (char_length(city) between 2 and 80),
  bio text not null default '' check (char_length(bio) <= 1000),
  interests text[] not null default '{}',
  photo_path text,
  approval_status text not null default 'pending' check (approval_status in ('pending','approved','rejected')),
  is_visible boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.ih_connections (
  id bigint generated always as identity primary key,
  requester uuid not null references auth.users(id) on delete cascade,
  recipient uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  check(requester <> recipient),
  unique(requester,recipient)
);
create table if not exists public.ih_messages (
  id bigint generated always as identity primary key,
  connection_id bigint not null references public.ih_connections(id) on delete cascade,
  sender uuid not null references auth.users(id) on delete cascade,
  body text not null check(char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create table if not exists public.ih_blocks (
  blocker uuid not null references auth.users(id) on delete cascade,
  blocked uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker,blocked),
  check(blocker <> blocked)
);
create table if not exists public.ih_reports (
  id bigint generated always as identity primary key,
  reporter uuid not null references auth.users(id) on delete cascade,
  reported_user uuid not null references auth.users(id) on delete cascade,
  reason text not null check(char_length(reason) between 10 and 1000),
  status text not null default 'open' check(status in ('open','reviewing','closed')),
  created_at timestamptz not null default now(),
  check(reporter <> reported_user)
);
create table if not exists public.ih_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.ih_profiles enable row level security;
alter table public.ih_connections enable row level security;
alter table public.ih_messages enable row level security;
alter table public.ih_blocks enable row level security;
alter table public.ih_reports enable row level security;
alter table public.ih_admins enable row level security;
-- Isolate all tables: no anonymous role access.
revoke all on public.ih_profiles,public.ih_connections,public.ih_messages,public.ih_blocks,public.ih_reports,public.ih_admins from anon;
grant select,insert on public.ih_profiles to authenticated;
grant select,insert on public.ih_connections to authenticated;
grant select,insert on public.ih_messages to authenticated;
grant select,insert,delete on public.ih_blocks to authenticated;
grant insert,select on public.ih_reports to authenticated;
-- Do NOT grant ih_admins to clients: assign admin through trusted dashboard only.
create policy "profile owner select or approved visible" on public.ih_profiles for select to authenticated using (
 user_id=(select auth.uid()) or (approval_status='approved' and is_visible=true
 and not exists(select 1 from public.ih_blocks b where
 (b.blocker=(select auth.uid()) and b.blocked=ih_profiles.user_id)
 or (b.blocked=(select auth.uid()) and b.blocker=ih_profiles.user_id)))
);
create policy "profile owner create pending" on public.ih_profiles for insert to authenticated
 with check(user_id=(select auth.uid()) and approval_status='pending' and is_visible=false and photo_path is null);
-- Updating requires a trusted server action: otherwise users could approve themselves.
-- No direct UPDATE policy intentionally.
create policy "connections participant view" on public.ih_connections for select to authenticated
 using ((select auth.uid()) in (requester,recipient));
create policy "request connection" on public.ih_connections for insert to authenticated
 with check(requester=(select auth.uid()) and status='pending' and
 exists(select 1 from public.ih_profiles p where p.user_id=recipient and p.approval_status='approved' and p.is_visible=true)
 and not exists(select 1 from public.ih_blocks b where
 (b.blocker=requester and b.blocked=recipient) or (b.blocker=recipient and b.blocked=requester)));
-- Accept/decline is intentionally server-only until a secure RPC validates transitions.
create policy "messages in accepted connection" on public.ih_messages for select to authenticated
 using(exists(select 1 from public.ih_connections c where c.id=connection_id and c.status='accepted'
 and (select auth.uid()) in (c.requester,c.recipient) and
 not exists(select 1 from public.ih_blocks b where
 (b.blocker=c.requester and b.blocked=c.recipient) or (b.blocker=c.recipient and b.blocked=c.requester))));
create policy "send in accepted connection" on public.ih_messages for insert to authenticated
 with check(sender=(select auth.uid()) and exists(select 1 from public.ih_connections c
 where c.id=connection_id and c.status='accepted' and (select auth.uid()) in (c.requester,c.recipient)
 and not exists(select 1 from public.ih_blocks b where
 (b.blocker=c.requester and b.blocked=c.recipient) or (b.blocker=c.recipient and b.blocked=c.requester))));
create policy "blocker manage own" on public.ih_blocks for select to authenticated using(blocker=(select auth.uid()));
create policy "blocker insert own" on public.ih_blocks for insert to authenticated with check(blocker=(select auth.uid()));
create policy "blocker delete own" on public.ih_blocks for delete to authenticated using(blocker=(select auth.uid()));
create policy "reporter submit" on public.ih_reports for insert to authenticated
 with check(reporter=(select auth.uid()) and status='open');
create policy "reporter see own" on public.ih_reports for select to authenticated using(reporter=(select auth.uid()));
-- Trusted admin access and photo handling require server routes and review before production.

-- Sequence access required for identity-backed inserts.
grant usage,select on all sequences in schema public to authenticated;
