-- Migration: Add completed_at_ms to pomodoro_sessions if not present
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'pomodoro_sessions' 
        AND column_name = 'completed_at_ms'
    ) THEN
        ALTER TABLE public.pomodoro_sessions 
        ADD COLUMN completed_at_ms BIGINT;
        
        -- Backfill existing rows from completed_at
        UPDATE public.pomodoro_sessions 
        SET completed_at_ms = (EXTRACT(EPOCH FROM completed_at) * 1000)::BIGINT
        WHERE completed_at_ms IS NULL AND completed_at IS NOT NULL;
    END IF;
END $$;
