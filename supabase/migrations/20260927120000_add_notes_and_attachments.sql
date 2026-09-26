-- ============================================================
-- Migration: Add notes and attachments support to tasks, revision subjects, and revision topics
-- ============================================================

-- 1. Tasks: add attachments jsonb column
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS attachments jsonb NOT NULL DEFAULT '[]'::jsonb;

-- 2. Revision subjects: add notes and attachments jsonb columns
ALTER TABLE public.revision_subjects
  ADD COLUMN IF NOT EXISTS notes jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS attachments jsonb NOT NULL DEFAULT '[]'::jsonb;

-- 3. Revision topics: add notes_data and attachments jsonb columns
ALTER TABLE public.revision_topics
  ADD COLUMN IF NOT EXISTS notes_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS attachments jsonb NOT NULL DEFAULT '[]'::jsonb;
