-- Migration: 20261116000000_phase0_init_schema_and_rls.sql
-- Enables UUID generation and sets up declarative tables with strict Row-Level Security (RLS) policies.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    avatar_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view own profile'
    ) THEN
        CREATE POLICY "Users can view own profile" ON public.profiles
            FOR SELECT TO authenticated USING (auth.uid() = id);
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update own profile'
    ) THEN
        CREATE POLICY "Users can update own profile" ON public.profiles
            FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- 2. Tasks Table
CREATE TABLE IF NOT EXISTS public.tasks (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    due_date TIMESTAMPTZ,
    has_time BOOLEAN NOT NULL DEFAULT FALSE,
    due_time TEXT,
    subtasks JSONB NOT NULL DEFAULT '[]'::jsonb,
    attachments JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    deleted_at_ms BIGINT,
    last_synced_at TIMESTAMPTZ
);
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'tasks' AND policyname = 'Users can access their own tasks'
    ) THEN
        CREATE POLICY "Users can access their own tasks" ON public.tasks
            FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tasks_user_active 
    ON public.tasks (user_id, deleted_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_user_due 
    ON public.tasks (user_id, completed, due_date ASC);

-- 3. Mindmaps Table
CREATE TABLE IF NOT EXISTS public.mindmaps (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    layout_type TEXT NOT NULL DEFAULT 'horizontal',
    nodes_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at_ms BIGINT NOT NULL,
    updated_at_ms BIGINT NOT NULL,
    deleted_at_ms BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);
ALTER TABLE public.mindmaps ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'mindmaps' AND policyname = 'Users can access their own mindmaps'
    ) THEN
        CREATE POLICY "Users can access their own mindmaps" ON public.mindmaps
            FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_mindmaps_user_updated 
    ON public.mindmaps (user_id, deleted_at_ms, updated_at_ms DESC);

-- 4. Pomodoro Sessions Table
CREATE TABLE IF NOT EXISTS public.pomodoro_sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    minutes INTEGER NOT NULL,
    mode TEXT NOT NULL DEFAULT 'focus',
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at_ms BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM now()) * 1000)::BIGINT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.pomodoro_sessions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'pomodoro_sessions' AND policyname = 'Users can access their own pomodoro sessions'
    ) THEN
        CREATE POLICY "Users can access their own pomodoro sessions" ON public.pomodoro_sessions
            FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pomodoro_user_completed 
    ON public.pomodoro_sessions (user_id, completed_at_ms DESC);

-- 5. Outbox Sync Queue Table
CREATE TABLE IF NOT EXISTS public.sync_outbox (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    feature TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    created_at_ms BIGINT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT
);
ALTER TABLE public.sync_outbox ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'sync_outbox' AND policyname = 'Users can access their own sync outbox'
    ) THEN
        CREATE POLICY "Users can access their own sync outbox" ON public.sync_outbox
            FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sync_outbox_account_order 
    ON public.sync_outbox (user_id, created_at_ms ASC);

-- 6. Protected App Configuration (Service-Role Only)
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS and revoke ALL access from client roles (anon, authenticated)
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.app_config FROM anon, authenticated;

-- Grant access ONLY to service_role (Edge Functions & MCP Server)
GRANT ALL ON public.app_config TO service_role;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'app_config' AND policyname = 'Allow service_role full access to app_config'
    ) THEN
        CREATE POLICY "Allow service_role full access to app_config" ON public.app_config
            FOR ALL TO service_role USING (true) WITH CHECK (true);
    END IF;
END $$;
