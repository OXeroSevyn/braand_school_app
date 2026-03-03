-- Braand School App Supabase Schema & RLS

-- 1. Custom Types
CREATE TYPE user_role AS ENUM ('super_admin', 'admin', 'team');
CREATE TYPE task_status AS ENUM ('pending', 'accepted', 'in_progress', 'completed');

-- 2. Tables

-- users (Public table for auth user profiles and roles)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  name TEXT,
  email TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'team',
  approved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- tasks
CREATE TABLE public.tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES public.users(id),
  created_by UUID REFERENCES public.users(id) NOT NULL,
  status task_status NOT NULL DEFAULT 'pending',
  comments TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Triggers for `updated_at` and new user profiles

-- Function: create a public.users row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, approved)
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'name',
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'team'),
    FALSE -- always false initially
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: call handle_new_user after insert on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Function: auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  new.updated_at = timezone('utc'::text, now());
  RETURN new;
END;
$$ LANGUAGE plpgsql;

-- Trigger for tasks
DROP TRIGGER IF EXISTS set_tasks_updated_at ON public.tasks;
CREATE TRIGGER set_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- 5. Enable Realtime
-- This is needed for dashboard auto-refresh & listening for status updates
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;

-- 6. RLS Policies

-- =========================================================================
-- `users` Table Policies
-- =========================================================================

-- Super Admin: Can do everything
CREATE POLICY "Super admins can do all on users" ON public.users FOR ALL
USING ( (SELECT role FROM public.users WHERE id = auth.uid()) = 'super_admin' );

-- Admin: Can read all team members and fellow admins (for dashboard visibility)
CREATE POLICY "Admins can view team members" ON public.users FOR SELECT
USING ( 
  (SELECT role FROM public.users WHERE id = auth.uid()) IN ('super_admin', 'admin') 
);

-- Note: Admins can update/approve only team members
CREATE POLICY "Admins can update team members" ON public.users FOR UPDATE
USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin' AND role = 'team'
);

-- Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT
USING ( id = auth.uid() );

CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE
USING ( id = auth.uid() );


-- =========================================================================
-- `tasks` Table Policies
-- =========================================================================

-- Super Admin: Can do everything
CREATE POLICY "Super admins can do all on tasks" ON public.tasks FOR ALL
USING ( (SELECT role FROM public.users WHERE id = auth.uid()) = 'super_admin' );

-- Admin: can fully manage (CRUD) tasks they created
CREATE POLICY "Admins can view tasks they created" ON public.tasks FOR SELECT
USING ( created_by = auth.uid() );

CREATE POLICY "Admins can insert tasks" ON public.tasks FOR INSERT
WITH CHECK ( created_by = auth.uid() );

CREATE POLICY "Admins can update tasks they created" ON public.tasks FOR UPDATE
USING ( created_by = auth.uid() );

CREATE POLICY "Admins can delete tasks they created" ON public.tasks FOR DELETE
USING ( created_by = auth.uid() );

-- Team: can view tasks assigned to them
CREATE POLICY "Team can view assigned tasks" ON public.tasks FOR SELECT
USING ( assigned_to = auth.uid() );

-- Team: can update tasks assigned to them (change status, add comments)
CREATE POLICY "Team can update assigned tasks" ON public.tasks FOR UPDATE
USING ( assigned_to = auth.uid() );


-- =========================================================================
-- Seed Super Admin Instructions
-- =========================================================================
-- Since Super Admin cannot sign up normally, the workflow is:
-- 1. Create a user via Supabase Dashboard -> Authentication -> Add User.
--    Use email: subhamdey.one@gmail.com and a safe password.
-- 2. Get that user's UUID from the auth dashboard.
-- 3. Run the following to update their row in the public.users table:
--
-- UPDATE public.users 
-- SET role = 'super_admin', approved = true 
-- WHERE email = 'subhamdey.one@gmail.com';
