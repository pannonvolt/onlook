-- Onlook Supabase initialization for a NEW project.
-- Based on migrations 0000 through 0019 from pannonvolt/onlook.
-- Run the entire file once in Supabase SQL Editor as the postgres role.
-- Changes: no storage deletions; corrected enum guard and enum/text comparisons.
-- All changes roll back on failure. Never use this on an existing app database.

BEGIN;
SET LOCAL search_path = public, extensions;

DO $init_guard$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
  ) THEN
    RAISE EXCEPTION 'Initialization stopped: public schema already has tables.';
  END IF;
END
$init_guard$;


-- Source: apps/backend/supabase/migrations/0000_same_human_robot.sql
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'frame_type') THEN
        CREATE TYPE "public"."frame_type" AS ENUM('web');
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'message_role') THEN
        CREATE TYPE "public"."message_role" AS ENUM('user', 'assistant');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS "canvas" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"scale" numeric NOT NULL,
	"x" numeric NOT NULL,
	"y" numeric NOT NULL
);


ALTER TABLE "canvas" ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS "frames" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"canvas_id" uuid NOT NULL,
	"type" "frame_type" NOT NULL,
	"url" varchar NOT NULL,
	"x" numeric NOT NULL,
	"y" numeric NOT NULL,
	"width" numeric NOT NULL,
	"height" numeric NOT NULL
);


ALTER TABLE "frames" ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS "conversations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"display_name" varchar,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


CREATE TABLE IF NOT EXISTS "messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"conversation_id" uuid NOT NULL,
	"content" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"role" "message_role" NOT NULL,
	"applied" boolean DEFAULT false NOT NULL,
	"snapshots" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"context" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"parts" jsonb DEFAULT '[]'::jsonb NOT NULL
);


CREATE TABLE IF NOT EXISTS "projects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar NOT NULL,
	"sandbox_id" varchar NOT NULL,
	"sandbox_url" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"preview_img" varchar,
	"description" text
);


ALTER TABLE "projects" ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS "users" (
	"id" uuid PRIMARY KEY NOT NULL
);


ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS "user_projects" (
	"user_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now(),
	CONSTRAINT "user_projects_user_id_project_id_pk" PRIMARY KEY("user_id","project_id")
);


ALTER TABLE "user_projects" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "canvas" DROP CONSTRAINT IF EXISTS "canvas_project_id_projects_id_fk";

ALTER TABLE "canvas" ADD CONSTRAINT "canvas_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "frames" DROP CONSTRAINT IF EXISTS "frames_canvas_id_canvas_id_fk";

ALTER TABLE "frames" ADD CONSTRAINT "frames_canvas_id_canvas_id_fk" FOREIGN KEY ("canvas_id") REFERENCES "public"."canvas"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "conversations" DROP CONSTRAINT IF EXISTS "conversations_project_id_projects_id_fk";

ALTER TABLE "conversations" ADD CONSTRAINT "conversations_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "messages" DROP CONSTRAINT IF EXISTS "messages_conversation_id_conversations_id_fk";

ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_conversations_id_fk" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "users_id_users_id_fk";

ALTER TABLE "users" ADD CONSTRAINT "users_id_users_id_fk" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "user_projects" DROP CONSTRAINT IF EXISTS "user_projects_user_id_users_id_fk";

ALTER TABLE "user_projects" ADD CONSTRAINT "user_projects_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "user_projects" DROP CONSTRAINT IF EXISTS "user_projects_project_id_projects_id_fk";

ALTER TABLE "user_projects" ADD CONSTRAINT "user_projects_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

-- Source: apps/backend/supabase/migrations/0001_graceful_exodus.sql
ALTER TABLE "conversations" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "messages" ENABLE ROW LEVEL SECURITY;

-- Source: apps/backend/supabase/migrations/0002_red_crusher_hogan.sql
CREATE TABLE IF NOT EXISTS "user_settings" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" uuid NOT NULL,
	"auto_apply_code" boolean DEFAULT true NOT NULL,
	"expand_code_blocks" boolean DEFAULT true NOT NULL,
	"show_suggestions" boolean DEFAULT true NOT NULL,
	"show_mini_chat" boolean DEFAULT true NOT NULL,
	CONSTRAINT "user_settings_user_id_unique" UNIQUE("user_id")
);


ALTER TABLE "user_settings" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "user_settings" DROP CONSTRAINT IF EXISTS "user_settings_user_id_users_id_fk";


ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE cascade;

-- Source: apps/backend/supabase/migrations/0003_loud_ozymandias.sql
CREATE TABLE IF NOT EXISTS "user_canvases" (
	"user_id" uuid NOT NULL,
	"canvas_id" uuid NOT NULL,
	"scale" numeric NOT NULL,
	"x" numeric NOT NULL,
	"y" numeric NOT NULL,
	CONSTRAINT "user_canvases_user_id_canvas_id_pk" PRIMARY KEY("user_id","canvas_id")
);


ALTER TABLE "user_canvases" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "user_canvases" DROP CONSTRAINT IF EXISTS user_canvases_user_id_users_id_fk;
ALTER TABLE "user_canvases" ADD CONSTRAINT "user_canvases_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "user_canvases" DROP CONSTRAINT IF EXISTS user_canvases_canvas_id_canvas_id_fk;
ALTER TABLE "user_canvases" ADD CONSTRAINT "user_canvases_canvas_id_canvas_id_fk" FOREIGN KEY ("canvas_id") REFERENCES "public"."canvas"("id") ON DELETE cascade ON UPDATE cascade;


-- Copy over the scale, x, and y values from the canvas table to the user_canvases table (if columns exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'canvas' AND column_name = 'scale') THEN
        INSERT INTO "user_canvases" ("user_id", "canvas_id", "scale", "x", "y")
        SELECT 
            up.user_id,
            c.id as canvas_id,
            c.scale,
            c.x,
            c.y
        FROM "canvas" c
        INNER JOIN "user_projects" up ON c.project_id = up.project_id
        ON CONFLICT (user_id, canvas_id) DO NOTHING;
    END IF;
END $$;

ALTER TABLE "canvas" DROP COLUMN IF EXISTS "scale";

ALTER TABLE "canvas" DROP COLUMN IF EXISTS "x";

ALTER TABLE "canvas" DROP COLUMN IF EXISTS "y";

-- Source: apps/backend/supabase/migrations/0004_pink_expediter.sql
-- Create ENUMs only if they don't exist
DO $$ BEGIN
    CREATE TYPE "public"."invitation_status" AS ENUM('pending', 'accepted', 'expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


DO $$ BEGIN
    CREATE TYPE "public"."project_role" AS ENUM('owner', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;


-- Create table only if it doesn't exist
CREATE TABLE IF NOT EXISTS "project_invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"inviter_id" uuid NOT NULL,
	"invitee_email" varchar NOT NULL,
	"status" "invitation_status" DEFAULT 'pending' NOT NULL,
	"token" varchar NOT NULL,
	"role" "project_role" NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "project_invitations_token_unique" UNIQUE("token")
);


ALTER TABLE "project_invitations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "user_projects" ADD COLUMN IF NOT EXISTS "role" "project_role";

-- Set all existing records to 'owner' role (assuming existing users should be owners)
UPDATE "user_projects" SET "role" = 'owner' WHERE "role" IS NULL;
-- Make the role column NOT NULL after setting default values
ALTER TABLE "user_projects" ALTER COLUMN "role" SET NOT NULL;

ALTER TABLE "project_invitations" DROP CONSTRAINT IF EXISTS "project_invitations_project_id_projects_id_fk";
ALTER TABLE "project_invitations" ADD CONSTRAINT "project_invitations_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "project_invitations" DROP CONSTRAINT IF EXISTS "project_invitations_inviter_id_users_id_fk";
ALTER TABLE "project_invitations" ADD CONSTRAINT "project_invitations_inviter_id_users_id_fk" FOREIGN KEY ("inviter_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE cascade;

-- Source: apps/backend/supabase/migrations/0005_short_lila_cheney.sql
ALTER TABLE "project_invitations" DROP COLUMN IF EXISTS "status";

ALTER TABLE "project_invitations" DROP CONSTRAINT IF EXISTS "project_invitations_invitee_email_project_id_unique";
ALTER TABLE "project_invitations" ADD CONSTRAINT "project_invitations_invitee_email_project_id_unique" UNIQUE("invitee_email","project_id");

DROP TYPE IF EXISTS "public"."invitation_status";

-- Source: apps/backend/supabase/migrations/0006_rls.sql
-- Helper function to check if user has specific roles for a project
CREATE OR REPLACE FUNCTION user_has_project_access(
  project_id_param UUID,
  required_roles TEXT[]
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_projects 
    WHERE user_projects.project_id = project_id_param
    AND user_projects.user_id = auth.uid()
    AND user_projects.role::text = ANY(required_roles)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user has project access via canvas
CREATE OR REPLACE FUNCTION user_has_canvas_access(
  canvas_id_param UUID,
  required_roles TEXT[]
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM canvas c
    JOIN user_projects up ON c.project_id = up.project_id
    WHERE c.id = canvas_id_param
    AND up.user_id = auth.uid()
    AND up.role::text = ANY(required_roles)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PROJECTS POLICIES
DROP POLICY IF EXISTS "projects_insert_policy" ON projects;

-- 1. INSERT: Allow only authenticated users to create projects
CREATE POLICY "projects_insert_policy" ON projects
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "projects_select_policy" ON projects;

-- 2. SELECT: Allow users who have an entry in user_projects for that project
CREATE POLICY "projects_select_policy" ON projects
FOR SELECT
TO authenticated
USING (user_has_project_access(projects.id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "projects_update_policy" ON projects;

-- 3. UPDATE: Allow users with 'owner' or 'admin' role in user_projects
CREATE POLICY "projects_update_policy" ON projects
FOR UPDATE
TO authenticated
USING (user_has_project_access(projects.id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "projects_delete_policy" ON projects;

-- 4. DELETE: Allow only users with 'owner' role
CREATE POLICY "projects_delete_policy" ON projects
FOR DELETE
TO authenticated
USING (user_has_project_access(projects.id, ARRAY['owner']));

-- CANVAS POLICIES
DROP POLICY IF EXISTS "canvas_insert_policy" ON canvas;

-- 1. INSERT: Allow only users with 'owner' role to create canvas entries
CREATE POLICY "canvas_insert_policy" ON canvas
FOR INSERT
TO authenticated
WITH CHECK (user_has_project_access(canvas.project_id, ARRAY['owner']));

DROP POLICY IF EXISTS "canvas_select_policy" ON canvas;
-- 2. SELECT: Allow users who have an entry in user_projects for the canvas's project
CREATE POLICY "canvas_select_policy" ON canvas
FOR SELECT
TO authenticated
USING (user_has_project_access(canvas.project_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "canvas_update_policy" ON canvas;
-- 3. UPDATE: Allow users with 'owner' or 'admin' role in user_projects for the canvas's project
CREATE POLICY "canvas_update_policy" ON canvas
FOR UPDATE
TO authenticated
USING (user_has_project_access(canvas.project_id, ARRAY['owner', 'admin']))
WITH CHECK (user_has_project_access(canvas.project_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "canvas_delete_policy" ON canvas;
-- 4. DELETE: Allow only users with 'owner' role for the canvas's project
CREATE POLICY "canvas_delete_policy" ON canvas
FOR DELETE
TO authenticated
USING (user_has_project_access(canvas.project_id, ARRAY['owner']));

-- USER_PROJECTS POLICIES
DROP POLICY IF EXISTS "user_projects_select_policy" ON user_projects;
-- 1. SELECT: Allow users to see their own entries or project owners/admins to see all entries
CREATE POLICY "user_projects_select_policy" ON user_projects
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_projects.user_id OR 
  user_has_project_access(user_projects.project_id, ARRAY['owner', 'admin'])
);

DROP POLICY IF EXISTS "user_projects_update_policy" ON user_projects;
-- 2. UPDATE: Allow only project owners/admins to update user roles
CREATE POLICY "user_projects_update_policy" ON user_projects
FOR UPDATE
TO authenticated
USING (user_has_project_access(user_projects.project_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "user_projects_delete_policy" ON user_projects;
-- 3. DELETE: Allow users to remove themselves or project owners to remove anyone
CREATE POLICY "user_projects_delete_policy" ON user_projects
FOR DELETE
TO authenticated
USING (
  auth.uid() = user_projects.user_id OR 
  user_has_project_access(user_projects.project_id, ARRAY['owner'])
);

-- USER_CANVASES POLICIES
DROP POLICY IF EXISTS "user_canvases_insert_policy" ON user_canvases;
-- 1. INSERT: Allow users to create their own canvas associations
CREATE POLICY "user_canvases_insert_policy" ON user_canvases
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_canvases.user_id
);

DROP POLICY IF EXISTS "user_canvases_select_policy" ON user_canvases;
-- 2. SELECT: Allow users to see only their own canvas associations
CREATE POLICY "user_canvases_select_policy" ON user_canvases
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_canvases.user_id
);

DROP POLICY IF EXISTS "user_canvases_update_policy" ON user_canvases;
-- 3. UPDATE: Allow users to update only their own canvas associations
CREATE POLICY "user_canvases_update_policy" ON user_canvases
FOR UPDATE
TO authenticated
USING (auth.uid() = user_canvases.user_id)
WITH CHECK (auth.uid() = user_canvases.user_id);

DROP POLICY IF EXISTS "user_canvases_delete_policy" ON user_canvases;
-- 4. DELETE: Allow users to delete only their own canvas associations
CREATE POLICY "user_canvases_delete_policy" ON user_canvases
FOR DELETE
TO authenticated
USING (auth.uid() = user_canvases.user_id);

-- FRAMES POLICIES
DROP POLICY IF EXISTS "frames_insert_policy" ON frames;
-- 1. INSERT: Allow project owners/admins to create frames
CREATE POLICY "frames_insert_policy" ON frames
FOR INSERT
TO authenticated
WITH CHECK (user_has_canvas_access(frames.canvas_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "frames_select_policy" ON frames;
-- 2. SELECT: Allow project owners/admins to view frames
CREATE POLICY "frames_select_policy" ON frames
FOR SELECT
TO authenticated
USING (user_has_canvas_access(frames.canvas_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "frames_update_policy" ON frames;
-- 3. UPDATE: Allow project owners/admins to update frames
CREATE POLICY "frames_update_policy" ON frames
FOR UPDATE
TO authenticated
USING (user_has_canvas_access(frames.canvas_id, ARRAY['owner', 'admin']))
WITH CHECK (user_has_canvas_access(frames.canvas_id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "frames_delete_policy" ON frames;
-- 4. DELETE: Allow project owners/admins to delete frames
CREATE POLICY "frames_delete_policy" ON frames
FOR DELETE
TO authenticated
USING (user_has_canvas_access(frames.canvas_id, ARRAY['owner', 'admin']));

-- USERS POLICIES
DROP POLICY IF EXISTS "users_insert_policy" ON users;
-- 1. INSERT: Allow users to create their own user record
CREATE POLICY "users_insert_policy" ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = users.id);

DROP POLICY IF EXISTS "users_select_policy" ON users;
-- 2. SELECT: Allow users to view only their own user record
CREATE POLICY "users_select_policy" ON users
FOR SELECT
TO authenticated
USING (auth.uid() = users.id);

DROP POLICY IF EXISTS "users_update_policy" ON users;
-- 3. UPDATE: Allow users to update only their own user record
CREATE POLICY "users_update_policy" ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = users.id)
WITH CHECK (auth.uid() = users.id);

DROP POLICY IF EXISTS "users_delete_policy" ON users;
-- 4. DELETE: Allow users to delete only their own user record
CREATE POLICY "users_delete_policy" ON users
FOR DELETE
TO authenticated
USING (auth.uid() = users.id);

-- USER_SETTINGS POLICIES
DROP POLICY IF EXISTS "user_settings_insert_policy" ON user_settings;
-- 1. INSERT: Allow users to create their own settings
CREATE POLICY "user_settings_insert_policy" ON user_settings
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_settings.user_id);

DROP POLICY IF EXISTS "user_settings_select_policy" ON user_settings;
-- 2. SELECT: Allow users to view only their own settings
CREATE POLICY "user_settings_select_policy" ON user_settings
FOR SELECT
TO authenticated
USING (auth.uid() = user_settings.user_id);

DROP POLICY IF EXISTS "user_settings_update_policy" ON user_settings;
-- 3. UPDATE: Allow users to update only their own settings
CREATE POLICY "user_settings_update_policy" ON user_settings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_settings.user_id)
WITH CHECK (auth.uid() = user_settings.user_id);

DROP POLICY IF EXISTS "user_settings_delete_policy" ON user_settings;
-- 4. DELETE: Allow users to delete only their own settings
CREATE POLICY "user_settings_delete_policy" ON user_settings
FOR DELETE
TO authenticated
USING (auth.uid() = user_settings.user_id);

-- PROJECT_INVITATIONS POLICIES
DROP POLICY IF EXISTS "project_invitations_insert_policy" ON project_invitations;
-- 1. INSERT: Allow project owners/admins to send invitations
CREATE POLICY "project_invitations_insert_policy" ON project_invitations
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = project_invitations.inviter_id AND
  user_has_project_access(project_invitations.project_id, ARRAY['owner', 'admin'])
);

DROP POLICY IF EXISTS "project_invitations_select_policy" ON project_invitations;
-- 2. SELECT: Allow project owners/admins and invitees to view invitations
CREATE POLICY "project_invitations_select_policy" ON project_invitations
FOR SELECT
TO authenticated
USING (
  user_has_project_access(project_invitations.project_id, ARRAY['owner', 'admin']) OR
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid() 
    AND auth.users.email = project_invitations.invitee_email
  )
);

DROP POLICY IF EXISTS "project_invitations_update_policy" ON project_invitations;
-- 3. UPDATE: Allow project owners/admins and invitees to update invitations
CREATE POLICY "project_invitations_update_policy" ON project_invitations
FOR UPDATE
TO authenticated
USING (
  user_has_project_access(project_invitations.project_id, ARRAY['owner', 'admin']) OR
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid() 
    AND auth.users.email = project_invitations.invitee_email
  )
)
WITH CHECK (
  user_has_project_access(project_invitations.project_id, ARRAY['owner', 'admin']) OR
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid() 
    AND auth.users.email = project_invitations.invitee_email
  )
);

DROP POLICY IF EXISTS "project_invitations_delete_policy" ON project_invitations;
-- 4. DELETE: Allow inviters, project owners/admins, and invitees to delete invitations
CREATE POLICY "project_invitations_delete_policy" ON project_invitations
FOR DELETE
TO authenticated
USING (
  auth.uid() = project_invitations.inviter_id OR
  user_has_project_access(project_invitations.project_id, ARRAY['owner', 'admin']) OR
  EXISTS (
    SELECT 1 FROM auth.users 
    WHERE auth.users.id = auth.uid() 
    AND auth.users.email = project_invitations.invitee_email
  )
);



-- Source: apps/backend/supabase/migrations/0007_realtime_rls.sql
CREATE OR REPLACE FUNCTION public.project_changes()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
  topic_project_id uuid;
BEGIN
  IF TG_TABLE_NAME = 'conversations' THEN
    SELECT c.project_id INTO topic_project_id
    FROM "conversations" c WHERE c.id = COALESCE(NEW.id, OLD.id);
  ELSIF TG_TABLE_NAME = 'messages' THEN
    SELECT c.project_id INTO topic_project_id
    FROM "messages" m INNER JOIN "conversations" c ON m.conversation_id = c.id
    WHERE m.id = COALESCE(NEW.id, OLD.id);
  END IF;

  -- Only broadcast if we found a valid project_id (i.e., not for projects table)
  IF topic_project_id IS NOT NULL THEN
    PERFORM realtime.broadcast_changes(
      'topic:' || topic_project_id::text, -- topic - the topic to which we're broadcasting
      TG_OP,                                             -- event - the event that triggered the function
      TG_OP,                                             -- operation - the operation that triggered the function
      TG_TABLE_NAME,                                     -- table - the table that caused the trigger
      TG_TABLE_SCHEMA,                                   -- schema - the schema of the table that caused the trigger
      NEW,                                               -- new record - the record after the change
      OLD                                                -- old record - the record before the change
    );
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS handle_conversations_changes ON public.conversations;
CREATE TRIGGER handle_conversations_changes
AFTER INSERT OR UPDATE OR DELETE
ON public.conversations
FOR EACH ROW
EXECUTE FUNCTION project_changes ();

DROP TRIGGER IF EXISTS handle_messages_changes ON public.messages;
CREATE TRIGGER handle_messages_changes
AFTER INSERT OR UPDATE OR DELETE
ON public.messages
FOR EACH ROW
EXECUTE FUNCTION project_changes ();

DROP POLICY IF EXISTS "Authenticated users can receive broadcasts" ON "realtime"."messages";
CREATE POLICY "Authenticated users can receive broadcasts"
ON "realtime"."messages"
FOR SELECT
TO authenticated
USING ( TRUE );

-- Source: apps/backend/supabase/migrations/0008_preview-img-storage.sql

insert into storage.buckets
  (id, name, public)
values
  ('preview_images', 'preview_images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow any users to select from preview_images files
drop policy if exists "preview_images_select_policy" on storage.objects;

create policy "preview_images_select_policy"
on storage.objects for select to public using (
    bucket_id = 'preview_images'
);

-- Allow any users to insert into preview_images files
drop policy if exists "preview_images_insert_policy" on storage.objects;

create policy "preview_images_insert_policy"
on storage.objects for insert to public with check (
    bucket_id = 'preview_images'
);


-- Source: apps/backend/supabase/migrations/0009_project_img_path.sql
ALTER TABLE "projects" DROP COLUMN IF EXISTS "preview_img_url";

ALTER TABLE "projects" DROP COLUMN IF EXISTS "preview_img_path";

ALTER TABLE "projects" DROP COLUMN IF EXISTS "preview_img_bucket";


ALTER TABLE "projects" ADD COLUMN "preview_img_url" varchar;

ALTER TABLE "projects" ADD COLUMN "preview_img_path" varchar;

ALTER TABLE "projects" ADD COLUMN "preview_img_bucket" varchar;


-- Source: apps/backend/supabase/migrations/0010_bent_edwin_jarvis.sql
-- Create new type
CREATE TYPE "public"."verification_request_status" AS ENUM('active', 'expired', 'used');

CREATE TABLE "custom_domains" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"apex_domain" text NOT NULL,
	"verified" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "custom_domains_apex_domain_unique" UNIQUE("apex_domain")
);


CREATE TABLE "preview_domains" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"full_domain" text NOT NULL,
	"project_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "preview_domains_full_domain_unique" UNIQUE("full_domain")
);


CREATE TABLE "published_domains" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"domain_id" uuid,
	"project_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"full_domain" text NOT NULL,
	CONSTRAINT "published_domains_domain_id_unique" UNIQUE("domain_id"),
	CONSTRAINT "published_domains_full_domain_unique" UNIQUE("full_domain")
);


CREATE TABLE "custom_domain_verification" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"domain_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"verification_id" text NOT NULL,
	"verification_code" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"status" "verification_request_status" DEFAULT 'active' NOT NULL
);


ALTER TABLE "preview_domains" ADD CONSTRAINT "preview_domains_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "published_domains" ADD CONSTRAINT "published_domains_domain_id_custom_domains_id_fk" FOREIGN KEY ("domain_id") REFERENCES "public"."custom_domains"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "published_domains" ADD CONSTRAINT "published_domains_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "custom_domain_verification" ADD CONSTRAINT "custom_domain_verification_domain_id_custom_domains_id_fk" FOREIGN KEY ("domain_id") REFERENCES "public"."custom_domains"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "custom_domain_verification" ADD CONSTRAINT "custom_domain_verification_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "projects" DROP COLUMN IF EXISTS "preview_img";

-- Source: apps/backend/supabase/migrations/0011_typical_clea.sql
;

CREATE TYPE "public"."price_keys" AS ENUM('PRO_MONTHLY_TIER_1', 'PRO_MONTHLY_TIER_2', 'PRO_MONTHLY_TIER_3', 'PRO_MONTHLY_TIER_4', 'PRO_MONTHLY_TIER_5', 'PRO_MONTHLY_TIER_6', 'PRO_MONTHLY_TIER_7', 'PRO_MONTHLY_TIER_8', 'PRO_MONTHLY_TIER_9', 'PRO_MONTHLY_TIER_10', 'PRO_MONTHLY_TIER_11');

CREATE TYPE "public"."product_type" AS ENUM('free', 'pro');

CREATE TYPE "public"."scheduled_subscription_action" AS ENUM('price_change', 'cancellation');

CREATE TYPE "public"."usage_types" AS ENUM('message', 'deployment');

CREATE TYPE "public"."subscription_status" AS ENUM('active', 'canceled');


CREATE TABLE "project_settings" (
	"project_id" uuid NOT NULL,
	"run_command" text DEFAULT '' NOT NULL,
	"build_command" text DEFAULT '' NOT NULL,
	"install_command" text DEFAULT '' NOT NULL,
	CONSTRAINT "project_settings_project_id_unique" UNIQUE("project_id")
);


ALTER TABLE "project_settings" ENABLE ROW LEVEL SECURITY;

CREATE TABLE "prices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"product_id" uuid NOT NULL,
	"price_key" "price_keys" NOT NULL,
	"monthly_message_limit" integer NOT NULL,
	"stripe_price_id" text NOT NULL,
	CONSTRAINT "prices_stripe_price_id_unique" UNIQUE("stripe_price_id")
);


ALTER TABLE "prices" ENABLE ROW LEVEL SECURITY;

CREATE TABLE "products" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"type" "product_type" NOT NULL,
	"stripe_product_id" text NOT NULL,
	CONSTRAINT "products_stripe_product_id_unique" UNIQUE("stripe_product_id")
);


ALTER TABLE "products" ENABLE ROW LEVEL SECURITY;

CREATE TABLE "subscriptions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"product_id" uuid NOT NULL,
	"price_id" uuid NOT NULL,
	"started_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"ended_at" timestamp with time zone,
	"status" "subscription_status" DEFAULT 'active' NOT NULL,
	"stripe_customer_id" text NOT NULL,
	"stripe_subscription_id" text NOT NULL,
	"stripe_subscription_item_id" text NOT NULL,
	"scheduled_action" "scheduled_subscription_action",
	"scheduled_price_id" uuid,
	"scheduled_change_at" timestamp with time zone,
	"stripe_subscription_schedule_id" text,
	CONSTRAINT "subscriptions_stripe_subscription_id_unique" UNIQUE("stripe_subscription_id"),
	CONSTRAINT "subscriptions_stripe_subscription_item_id_unique" UNIQUE("stripe_subscription_item_id")
);


ALTER TABLE "subscriptions" ENABLE ROW LEVEL SECURITY;

CREATE TABLE "usage_records" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"type" "usage_types" DEFAULT 'message' NOT NULL,
	"timestamp" timestamp with time zone NOT NULL
);


ALTER TABLE "usage_records" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "custom_domains" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "preview_domains" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "published_domains" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "custom_domain_verification" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "custom_domain_verification" ALTER COLUMN "status" SET DATA TYPE "public"."verification_request_status";

ALTER TABLE "custom_domain_verification" ALTER COLUMN "status" SET DEFAULT 'active';

ALTER TABLE "messages" ADD COLUMN "commit_oid" text;

ALTER TABLE "user_settings" ADD COLUMN "should_warn_delete" boolean DEFAULT true NOT NULL;

ALTER TABLE "project_settings" ADD CONSTRAINT "project_settings_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "prices" ADD CONSTRAINT "prices_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_product_id_products_id_fk" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_price_id_prices_id_fk" FOREIGN KEY ("price_id") REFERENCES "public"."prices"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_scheduled_price_id_prices_id_fk" FOREIGN KEY ("scheduled_price_id") REFERENCES "public"."prices"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "usage_records" ADD CONSTRAINT "usage_records_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;

DROP TYPE IF EXISTS "public"."status";

-- Source: apps/backend/supabase/migrations/0012_file-transfer-bucket.sql

insert into storage.buckets
  (id, name, public)
values
  ('file_transfer', 'file_transfer', false)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to select only their own files from file_transfer
drop policy if exists "file_transfer_select_policy" on storage.objects;

create policy "file_transfer_select_policy"
on storage.objects for select to authenticated using (
    bucket_id = 'file_transfer' AND auth.uid() = owner
);

-- Allow authenticated users to insert into file_transfer with their user ID as owner
drop policy if exists "file_transfer_insert_policy" on storage.objects;

create policy "file_transfer_insert_policy"
on storage.objects for insert to authenticated with check (
    bucket_id = 'file_transfer' AND auth.uid() = owner
);

-- Allow authenticated users to delete only their own files
drop policy if exists "file_transfer_delete_policy" on storage.objects;

create policy "file_transfer_delete_policy"
on storage.objects for delete to authenticated using (
    bucket_id = 'file_transfer' AND auth.uid() = owner
);


-- Source: apps/backend/supabase/migrations/0013_aspiring_kabuki.sql
CREATE TYPE "public"."project_create_status" AS ENUM('pending', 'completed', 'failed');

CREATE TYPE "public"."deployment_status" AS ENUM('in_progress', 'completed', 'failed');

CREATE TYPE "public"."deployment_type" AS ENUM('preview', 'custom', 'unpublish_preview', 'unpublish_custom');

CREATE TABLE "project_create_requests" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"context" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"status" "project_create_status" DEFAULT 'pending' NOT NULL,
	CONSTRAINT "project_create_requests_project_id_unique" UNIQUE("project_id")
);


ALTER TABLE "project_create_requests" ENABLE ROW LEVEL SECURITY;

CREATE TABLE "deployments" (
	"id" uuid PRIMARY KEY NOT NULL,
	"requested_by" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"sandbox_id" text,
	"urls" text[],
	"type" "deployment_type" NOT NULL,
	"status" "deployment_status" NOT NULL,
	"message" text,
	"build_log" text,
	"error" text,
	"progress" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE "deployments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "users" ADD COLUMN "first_name" text;

ALTER TABLE "users" ADD COLUMN "last_name" text;

ALTER TABLE "users" ADD COLUMN "display_name" text;

ALTER TABLE "users" ADD COLUMN "avatar_url" text;

ALTER TABLE "users" ADD COLUMN "email" text;

ALTER TABLE "users" ADD COLUMN "created_at" timestamp with time zone DEFAULT now() NOT NULL;

ALTER TABLE "users" ADD COLUMN "updated_at" timestamp with time zone DEFAULT now() NOT NULL;

ALTER TABLE "project_create_requests" ADD CONSTRAINT "project_create_requests_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "deployments" ADD CONSTRAINT "deployments_requested_by_users_id_fk" FOREIGN KEY ("requested_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "deployments" ADD CONSTRAINT "deployments_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE no action ON UPDATE no action;

-- Source: apps/backend/supabase/migrations/0014_military_marrow.sql
CREATE TYPE "public"."project_custom_domain_status" AS ENUM('active', 'cancelled');

CREATE TABLE "project_custom_domains" (
	"full_domain" text NOT NULL,
	"custom_domain_id" uuid NOT NULL,
	"project_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"status" "project_custom_domain_status" DEFAULT 'active' NOT NULL,
	CONSTRAINT "project_custom_domains_custom_domain_id_project_id_pk" PRIMARY KEY("custom_domain_id","project_id")
);


ALTER TABLE "project_custom_domains" ENABLE ROW LEVEL SECURITY;

DROP TABLE "published_domains" CASCADE;

ALTER TABLE "custom_domain_verification" RENAME COLUMN "domain_id" TO "custom_domain_id";

ALTER TABLE "custom_domain_verification" RENAME COLUMN "verification_id" TO "freestyle_verification_id";

ALTER TABLE "custom_domain_verification" DROP CONSTRAINT "custom_domain_verification_domain_id_custom_domains_id_fk";


ALTER TABLE "custom_domain_verification" DROP COLUMN "status";

DROP TYPE IF EXISTS "public"."verification_request_status";

CREATE TYPE "public"."verification_request_status" AS ENUM('pending', 'verified', 'cancelled');

ALTER TABLE "custom_domain_verification" ADD COLUMN "status" "verification_request_status" NOT NULL DEFAULT 'pending';

ALTER TABLE "custom_domain_verification" ADD COLUMN "full_domain" text NOT NULL;

ALTER TABLE "custom_domain_verification" ADD COLUMN "txt_record" jsonb NOT NULL;

ALTER TABLE "custom_domain_verification" ADD COLUMN "a_records" jsonb DEFAULT '[]'::jsonb NOT NULL;

ALTER TABLE "project_custom_domains" ADD CONSTRAINT "project_custom_domains_custom_domain_id_custom_domains_id_fk" FOREIGN KEY ("custom_domain_id") REFERENCES "public"."custom_domains"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "project_custom_domains" ADD CONSTRAINT "project_custom_domains_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "custom_domain_verification" ADD CONSTRAINT "custom_domain_verification_custom_domain_id_custom_domains_id_fk" FOREIGN KEY ("custom_domain_id") REFERENCES "public"."custom_domains"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "custom_domain_verification" DROP COLUMN "verification_code";

-- Source: apps/backend/supabase/migrations/0015_same_leo.sql


ALTER TYPE "public"."deployment_status" ADD VALUE 'pending' BEFORE 'in_progress';

ALTER TYPE "public"."deployment_status" ADD VALUE 'cancelled';

CREATE TABLE "legacy_subscriptions" (
	"email" text PRIMARY KEY NOT NULL,
	"stripe_coupon_id" text NOT NULL,
	"stripe_promotion_code_id" text NOT NULL,
	"stripe_promotion_code" text NOT NULL,
	"redeem_at" timestamp with time zone,
	"redeem_by" timestamp with time zone
);


ALTER TABLE "legacy_subscriptions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "deployments" ADD COLUMN "build_script" text;

ALTER TABLE "deployments" ADD COLUMN "build_flags" text;

ALTER TABLE "deployments" ADD COLUMN "env_vars" jsonb;

-- Source: apps/backend/supabase/migrations/0016_pretty_dust.sql
CREATE TABLE "rate_limits" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"subscription_id" uuid NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"started_at" timestamp with time zone NOT NULL,
	"ended_at" timestamp with time zone NOT NULL,
	"max" integer NOT NULL,
	"left" integer DEFAULT 0 NOT NULL,
	"carry_over_key" uuid NOT NULL,
	"carry_over_total" integer DEFAULT 0 NOT NULL,
	"stripe_subscription_item_id" text NOT NULL
);


ALTER TABLE "rate_limits" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "messages" ALTER COLUMN "applied" DROP DEFAULT;

ALTER TABLE "messages" ALTER COLUMN "applied" DROP NOT NULL;

ALTER TABLE "messages" ALTER COLUMN "snapshots" DROP DEFAULT;

ALTER TABLE "messages" ALTER COLUMN "snapshots" DROP NOT NULL;

ALTER TABLE "conversations" ADD COLUMN "suggestions" jsonb DEFAULT '[]'::jsonb;

ALTER TABLE "messages" ADD COLUMN "checkpoints" jsonb DEFAULT '[]'::jsonb NOT NULL;

ALTER TABLE "subscriptions" ADD COLUMN "stripe_current_period_start" timestamp with time zone NOT NULL;

ALTER TABLE "subscriptions" ADD COLUMN "stripe_current_period_end" timestamp with time zone NOT NULL;

ALTER TABLE "users" ADD COLUMN "stripe_customer_id" text;

ALTER TABLE "rate_limits" ADD CONSTRAINT "rate_limits_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;

ALTER TABLE "rate_limits" ADD CONSTRAINT "rate_limits_subscription_id_subscriptions_id_fk" FOREIGN KEY ("subscription_id") REFERENCES "public"."subscriptions"("id") ON DELETE no action ON UPDATE no action;

CREATE INDEX "rate_limits_user_time_idx" ON "rate_limits" USING btree ("user_id","started_at","ended_at");

CREATE INDEX "usage_records_user_time_idx" ON "usage_records" USING btree ("user_id","timestamp");


-- Source: apps/backend/supabase/migrations/0017_small_xavin.sql


CREATE TABLE "feedbacks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"email" text,
	"message" text NOT NULL,
	"page_url" text,
	"user_agent" text,
	"attachments" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE "feedbacks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "project_invitations" DROP CONSTRAINT "project_invitations_invitee_email_project_id_unique";

ALTER TABLE "custom_domain_verification" DROP CONSTRAINT "custom_domain_verification_project_id_projects_id_fk";


ALTER TABLE "preview_domains" DROP CONSTRAINT "preview_domains_project_id_projects_id_fk";


ALTER TABLE "deployments" DROP CONSTRAINT "deployments_project_id_projects_id_fk";


ALTER TABLE "projects" ADD COLUMN "tags" varchar[] DEFAULT '{}';

ALTER TABLE "projects" ADD COLUMN "updated_preview_img_at" timestamp with time zone;

ALTER TABLE "feedbacks" ADD CONSTRAINT "feedbacks_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE cascade;

ALTER TABLE "custom_domain_verification" ADD CONSTRAINT "custom_domain_verification_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "preview_domains" ADD CONSTRAINT "preview_domains_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "deployments" ADD CONSTRAINT "deployments_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

CREATE INDEX "project_invitations_invitee_email_project_id_idx" ON "project_invitations" USING btree ("invitee_email","project_id");

-- Source: apps/backend/supabase/migrations/0018_lush_thanos.sql
CREATE TABLE "branches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"name" varchar NOT NULL,
	"description" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL,
	"git_branch" varchar,
	"git_commit_sha" varchar,
	"git_repo_url" varchar,
	"sandbox_id" varchar NOT NULL
);


ALTER TABLE "branches" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "frames" ALTER COLUMN "type" SET DATA TYPE text;

ALTER TABLE "frames" ALTER COLUMN "type" DROP NOT NULL;

ALTER TABLE "projects" ALTER COLUMN "sandbox_id" DROP NOT NULL;

ALTER TABLE "projects" ALTER COLUMN "sandbox_url" DROP NOT NULL;

ALTER TABLE "frames" ADD COLUMN "branch_id" uuid;

ALTER TABLE "usage_records" ADD COLUMN "trace_id" varchar(255);

ALTER TABLE "branches" ADD CONSTRAINT "branches_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE cascade;

CREATE INDEX "branches_project_id_idx" ON "branches" USING btree ("project_id");

CREATE UNIQUE INDEX "branches_name_per_project_ux" ON "branches" USING btree ("project_id","name");

CREATE UNIQUE INDEX "branches_default_per_project_ux" ON "branches" USING btree ("project_id") WHERE "branches"."is_default" = true;

ALTER TABLE "frames" ADD CONSTRAINT "frames_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE cascade ON UPDATE cascade;

ALTER TABLE "usage_records" ADD CONSTRAINT "usage_records_user_trace_idx" UNIQUE("user_id","trace_id");

DROP TYPE "public"."frame_type";

-- Source: apps/backend/supabase/migrations/0019_abandoned_psylocke.sql
ALTER TYPE "public"."message_role" ADD VALUE 'system';

ALTER TABLE "users" ADD COLUMN "github_installation_id" text;

-- Pin SECURITY DEFINER lookup to the application schema.
ALTER FUNCTION public.user_has_project_access(uuid, text[]) SET search_path = public;
ALTER FUNCTION public.user_has_canvas_access(uuid, text[]) SET search_path = public;
ALTER FUNCTION public.project_changes() SET search_path = public;

-- Supabase API roles still obey row level security.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

COMMIT;

-- Verification: returns the installed application tables.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
