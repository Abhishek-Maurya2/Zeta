-- Persist the revision progress fields emitted by ChapterTopic.toSupabaseRow.
alter table public.revision_topics
  add column if not exists revision_stage integer,
  add column if not exists last_revised_at timestamptz,
  add column if not exists next_revision_date timestamptz;

-- Make the columns immediately visible to PostgREST.
notify pgrst, 'reload schema';
