create table if not exists public.legacy_workspace_claims (
  claim_key text primary key,
  claimed_by uuid not null references auth.users(id) on delete restrict,
  claimed_at timestamptz not null default now()
);
alter table public.legacy_workspace_claims enable row level security;
revoke all on public.legacy_workspace_claims from public, anon, authenticated;

create or replace function public.claim_legacy_workspace()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  claimant uuid := auth.uid();
  existing_claimant uuid;
begin
  if claimant is null then
    raise exception 'Authentication required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('zeta-singleton-workspace-claim')
  );

  insert into public.legacy_workspace_claims (claim_key, claimed_by)
  values ('singleton', claimant)
  on conflict (claim_key) do nothing;

  select claimed_by into existing_claimant
  from public.legacy_workspace_claims
  where claim_key = 'singleton'
  for update;

  if existing_claimant <> claimant then
    return false;
  end if;

  insert into public.profiles
    (id, display_name, email, avatar_image, settings, created_at, updated_at)
  select claimant::text, display_name, email, avatar_image, settings, created_at, updated_at
  from public.profiles
  where id = 'singleton'
  on conflict (id) do update set
    display_name = case when public.profiles.display_name = ''
      then excluded.display_name else public.profiles.display_name end,
    email = case when public.profiles.email = ''
      then excluded.email else public.profiles.email end,
    avatar_image = coalesce(public.profiles.avatar_image, excluded.avatar_image),
    settings = excluded.settings || public.profiles.settings,
    updated_at = greatest(public.profiles.updated_at, excluded.updated_at);

  delete from public.profiles where id = 'singleton';
  update public.tasks set user_id = claimant::text where user_id = 'singleton';
  update public.pomodoro_sessions set user_id = claimant::text where user_id = 'singleton';
  update public.pomodoro_settings set user_id = claimant::text where user_id = 'singleton';
  update public.revision_subjects set user_id = claimant::text where user_id = 'singleton';
  update public.revision_topics set user_id = claimant::text where user_id = 'singleton';
  update public.weather_locations set user_id = claimant::text where user_id = 'singleton';

  return true;
end;
$$;
revoke all on function public.claim_legacy_workspace() from public, anon;
grant execute on function public.claim_legacy_workspace() to authenticated;

drop policy if exists "Single user can manage tasks" on public.tasks;
alter table public.tasks alter column user_id drop default;
revoke all on public.tasks from public, anon;
grant select, insert, update, delete on public.tasks to authenticated;
drop policy if exists "Zeta users manage their tasks" on public.tasks;
create policy "Zeta users manage their tasks" on public.tasks for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

drop policy if exists "Single user can manage pomodoro sessions" on public.pomodoro_sessions;
alter table public.pomodoro_sessions alter column user_id drop default;
revoke all on public.pomodoro_sessions from public, anon;
grant select, insert, update, delete on public.pomodoro_sessions to authenticated;
drop policy if exists "Zeta users manage their pomodoro sessions" on public.pomodoro_sessions;
create policy "Zeta users manage their pomodoro sessions" on public.pomodoro_sessions for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

drop policy if exists "Single user can manage pomodoro settings" on public.pomodoro_settings;
alter table public.pomodoro_settings alter column user_id drop default;
revoke all on public.pomodoro_settings from public, anon;
grant select, insert, update, delete on public.pomodoro_settings to authenticated;
drop policy if exists "Zeta users manage their pomodoro settings" on public.pomodoro_settings;
create policy "Zeta users manage their pomodoro settings" on public.pomodoro_settings for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

drop policy if exists "Single user can manage revision subjects" on public.revision_subjects;
alter table public.revision_subjects alter column user_id drop default;
revoke all on public.revision_subjects from public, anon;
grant select, insert, update, delete on public.revision_subjects to authenticated;
drop policy if exists "Zeta users manage their revision subjects" on public.revision_subjects;
create policy "Zeta users manage their revision subjects" on public.revision_subjects for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

drop policy if exists "Single user can manage revision topics" on public.revision_topics;
alter table public.revision_topics alter column user_id drop default;
revoke all on public.revision_topics from public, anon;
grant select, insert, update, delete on public.revision_topics to authenticated;
drop policy if exists "Zeta users manage their revision topics" on public.revision_topics;
create policy "Zeta users manage their revision topics" on public.revision_topics for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

drop policy if exists "Single user can manage profile" on public.profiles;
alter table public.profiles alter column id drop default;
revoke all on public.profiles from public, anon;
grant select, insert, update, delete on public.profiles to authenticated;
drop policy if exists "Zeta users manage their profile" on public.profiles;
create policy "Zeta users manage their profile" on public.profiles for all to authenticated
  using ((select auth.uid())::text = id)
  with check ((select auth.uid())::text = id);

drop policy if exists "Single user can manage weather location" on public.weather_locations;
alter table public.weather_locations alter column user_id drop default;
revoke all on public.weather_locations from public, anon;
grant select, insert, update, delete on public.weather_locations to authenticated;
drop policy if exists "Zeta users manage their weather location" on public.weather_locations;
create policy "Zeta users manage their weather location" on public.weather_locations for all to authenticated
  using ((select auth.uid())::text = user_id)
  with check ((select auth.uid())::text = user_id);

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "Zeta avatar images are public" on storage.objects;
create policy "Zeta avatar images are public" on storage.objects
  for select to public using (bucket_id = 'avatars');
drop policy if exists "Zeta users upload own avatar" on storage.objects;
create policy "Zeta users upload own avatar" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Zeta users update own avatar" on storage.objects;
create policy "Zeta users update own avatar" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Zeta users delete own avatar" on storage.objects;
create policy "Zeta users delete own avatar" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
