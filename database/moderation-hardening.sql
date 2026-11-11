-- Island Hearts moderation hardening, applied to the dedicated Supabase project.
-- No direct browser access to administrator identities or moderation decisions.
create table public.ih_moderation_log (
  id bigint generated always as identity primary key,
  target_user uuid not null references auth.users(id) on delete cascade,
  decision text not null check (decision in ('approved','rejected')),
  reviewer_note text not null check (char_length(reviewer_note) between 4 and 500),
  reviewed_at timestamptz not null default now(),
  reviewer_source text not null default current_user
);
alter table public.ih_moderation_log enable row level security;
revoke all on table public.ih_moderation_log from public, anon, authenticated;
revoke all on table public.ih_admins from public, anon, authenticated;
revoke all on sequence public.ih_moderation_log_id_seq from public, anon, authenticated;
revoke usage,select on all sequences in schema public from authenticated;
grant usage,select on sequence public.ih_connections_id_seq,public.ih_messages_id_seq,public.ih_reports_id_seq to authenticated;
create index ih_profiles_approved_city_gender on public.ih_profiles(city,gender) where approval_status='approved' and is_visible=true;
create index ih_messages_connection_created on public.ih_messages(connection_id,created_at);
