-- Bring the historical migrations up to date with the current chat schema.
-- Safe to run again; existing conversations and messages are preserved.
BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'public' AND t.typname = 'agent_type'
    ) THEN
        CREATE TYPE public.agent_type AS ENUM ('root', 'user');
    END IF;
END $$;

ALTER TABLE public.conversations
    ADD COLUMN IF NOT EXISTS agent_type public.agent_type DEFAULT 'root';

ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS usage jsonb;

COMMIT;
