-- Supabase Schema for Atlas Workout

-- 1. ENUMS & EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE (Linked to auth.users)
CREATE TABLE public.social_users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to create a user in social_users when they sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.social_users(id, display_name)
  VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- 3. APP STORE GUIDES (Blocks & Reports)
CREATE TABLE public.user_blocks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  blocker_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id)
);

CREATE TABLE public.user_reports (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reported_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. GROUPS
CREATE TABLE public.groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  invite_token TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.group_members (
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin' or 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

-- 5. WORKOUTS
CREATE TABLE public.workout_sessions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  duration_minutes INTEGER,
  calories REAL,
  exercise_count INTEGER,
  total_sets INTEGER,
  total_volume REAL,
  title TEXT,
  created_at TEXT
);

-- 6. ROW LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.social_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;

-- Users can only see profiles of people they haven't blocked and who haven't blocked them
CREATE POLICY "Users can view non-blocked profiles" ON public.social_users
  FOR SELECT USING (
    id NOT IN (
      SELECT blocked_id FROM public.user_blocks WHERE blocker_id = auth.uid()
    )
    AND
    id NOT IN (
      SELECT blocker_id FROM public.user_blocks WHERE blocked_id = auth.uid()
    )
  );

-- Users can manage their own profile
CREATE POLICY "Users can edit own profile" ON public.social_users
  FOR UPDATE USING (auth.uid() = id);

-- Groups RLS
CREATE POLICY "Users can view groups they belong to" ON public.groups
  FOR SELECT USING (
    id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Group Members RLS
CREATE POLICY "Users can view members of their groups" ON public.group_members
  FOR SELECT USING (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Workout Sessions RLS (Only view friends in the same group, that are not blocked)
CREATE POLICY "Users can view mutual group members workouts" ON public.workout_sessions
  FOR SELECT USING (
    user_id = auth.uid() OR (
      user_id IN (
        SELECT user_id FROM public.group_members WHERE group_id IN (
          SELECT group_id FROM public.group_members WHERE user_id = auth.uid()
        )
      )
      AND user_id NOT IN (SELECT blocked_id FROM public.user_blocks WHERE blocker_id = auth.uid())
      AND user_id NOT IN (SELECT blocker_id FROM public.user_blocks WHERE blocked_id = auth.uid())
    )
  );

CREATE POLICY "Users can insert own workouts" ON public.workout_sessions
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workouts" ON public.workout_sessions
  FOR UPDATE USING (user_id = auth.uid());

-- RPC FUNCTION: FOR DELETING USER ACCOUNT (Guideline 5.1.1)
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void AS $$
BEGIN
  -- Data in public tables will cascade automatically because of 'ON DELETE CASCADE'
  -- Deleting the user from auth.users triggers the cascades
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
