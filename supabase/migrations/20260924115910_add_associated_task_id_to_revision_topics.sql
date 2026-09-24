-- Keep revision topic task associations available in the cloud replica.
-- The client models task IDs as strings, so retain that representation here.
alter table public.revision_topics
  add column if not exists associated_task_id text;

-- Make the new column immediately visible to PostgREST.
notify pgrst, 'reload schema';
