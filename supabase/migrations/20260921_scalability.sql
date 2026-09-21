-- ============================================================
-- Zeta Scalability Migration
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- ─── 1. Indexes on `tasks` ────────────────────────────────────────────────────

-- Fast incremental sync: pull tasks updated since last sync
CREATE INDEX IF NOT EXISTS idx_tasks_user_updated_at
  ON public.tasks (user_id, updated_at DESC);

-- Fast load of active tasks (no deleted_at filter)
CREATE INDEX IF NOT EXISTS idx_tasks_user_active
  ON public.tasks (user_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- Fast load of bin (only deleted tasks)
CREATE INDEX IF NOT EXISTS idx_tasks_user_bin
  ON public.tasks (user_id, deleted_at DESC)
  WHERE deleted_at IS NOT NULL;

-- ─── 2. Indexes on `pomodoro_sessions` ────────────────────────────────────────

-- Fast incremental sync + stats aggregation
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_completed_at
  ON public.pomodoro_sessions (user_id, completed_at DESC);

-- ─── 3. Session Daily Stats — Materialized View ───────────────────────────────
-- Pre-aggregates per (user, day, mode) to avoid scanning all sessions for stats UI.

CREATE MATERIALIZED VIEW IF NOT EXISTS public.session_daily_stats AS
  SELECT
    user_id,
    DATE(completed_at AT TIME ZONE 'UTC') AS day,
    mode,
    SUM(minutes)::integer  AS total_minutes,
    COUNT(*)::integer       AS session_count
  FROM public.pomodoro_sessions
  GROUP BY user_id, DATE(completed_at AT TIME ZONE 'UTC'), mode
WITH DATA;

-- Unique index required for REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS uidx_session_daily_stats_key
  ON public.session_daily_stats (user_id, day, mode);

-- ─── 4. Grant select on materialized view ─────────────────────────────────────
-- Materialized views cannot have RLS directly.
-- The app must always filter by user_id in its query.

GRANT SELECT ON public.session_daily_stats TO authenticated;
GRANT SELECT ON public.session_daily_stats TO anon;

-- ─── 5. pg_cron Auto-Purge Jobs ───────────────────────────────────────────────
-- Requires pg_cron extension. Enable it in Supabase Dashboard > Extensions first.
-- Then uncomment and run these cron.schedule calls:

-- Purge bin tasks older than 90 days — runs daily at 03:00 UTC
-- SELECT cron.schedule(
--   'zeta-purge-old-bin-tasks',
--   '0 3 * * *',
--   $$
--     DELETE FROM public.tasks
--     WHERE deleted_at IS NOT NULL
--       AND deleted_at < (now() AT TIME ZONE 'UTC') - INTERVAL '90 days';
--   $$
-- );

-- Purge pomodoro sessions older than 365 days — runs weekly Sunday 04:00 UTC
-- SELECT cron.schedule(
--   'zeta-purge-old-sessions',
--   '0 4 * * 0',
--   $$
--     DELETE FROM public.pomodoro_sessions
--     WHERE completed_at < (now() AT TIME ZONE 'UTC') - INTERVAL '365 days';
--   $$
-- );

-- Refresh materialized view nightly at 02:00 UTC
-- SELECT cron.schedule(
--   'zeta-refresh-session-daily-stats',
--   '0 2 * * *',
--   $$
--     REFRESH MATERIALIZED VIEW CONCURRENTLY public.session_daily_stats;
--   $$
-- );

-- ─── 6. Verify scheduled jobs ─────────────────────────────────────────────────
-- SELECT jobid, jobname, schedule, command FROM cron.job WHERE jobname LIKE 'zeta-%';

-- ─── 7. Verify indexes ────────────────────────────────────────────────────────
-- SELECT indexname, tablename FROM pg_indexes
-- WHERE tablename IN ('tasks', 'pomodoro_sessions')
-- ORDER BY tablename, indexname;
