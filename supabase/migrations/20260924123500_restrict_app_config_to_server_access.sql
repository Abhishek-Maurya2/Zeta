-- app_config contains the private GitHub release token. Only trusted server
-- processes (service_role) may read or write it; app clients use the updater
-- Edge Function instead.
alter table public.app_config enable row level security;
drop policy if exists "Allow public read access to app_config"
  on public.app_config;
revoke all on table public.app_config from public, anon, authenticated;
