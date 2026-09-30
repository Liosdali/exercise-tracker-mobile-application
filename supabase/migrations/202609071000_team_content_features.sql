-- Team Content Features Migration
-- Adds Activity Feed, Program Suggestions, and Leaderboard functionality

-- ============================================================================
-- 1. TEAM ACTIVITY LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.team_activity_log (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  workouts_count INTEGER NOT NULL DEFAULT 0,
  total_calories REAL DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_duration_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, activity_date)
);

CREATE INDEX IF NOT EXISTS idx_team_activity_log_team_date ON public.team_activity_log(team_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_team_activity_log_user_date ON public.team_activity_log(user_id, activity_date);

-- ============================================================================
-- 2. PROGRAM SUGGESTIONS TABLE
-- ============================================================================

-- Postgres'te CREATE TYPE ... IF NOT EXISTS yok; migration'in tekrar
-- calistirilabilir kalmasi icin istisna yakalaniyor.
DO $enum$ BEGIN
  CREATE TYPE suggestion_type AS ENUM ('exercise', 'program_change', 'feedback');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;

DO $enum$ BEGIN
  CREATE TYPE suggestion_status AS ENUM ('pending', 'accepted', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;

CREATE TABLE IF NOT EXISTS public.program_suggestions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  suggestion_type suggestion_type NOT NULL,
  related_exercise_id UUID,
  related_program_id UUID,
  message TEXT,
  response_message TEXT,
  status suggestion_status DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_program_suggestions_to_user ON public.program_suggestions(to_user_id, status);
CREATE INDEX IF NOT EXISTS idx_program_suggestions_team ON public.program_suggestions(team_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_program_suggestions_from_user ON public.program_suggestions(from_user_id);

-- ============================================================================
-- 3. TEAM LEADERBOARD TABLES (Periodic Aggregation)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.team_leaderboard_weekly (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  workout_count INTEGER DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_calories REAL DEFAULT 0,
  rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, week_start_date)
);

CREATE TABLE IF NOT EXISTS public.team_leaderboard_monthly (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month_start_date DATE NOT NULL,
  workout_count INTEGER DEFAULT 0,
  total_weight_lifted DECIMAL(10, 2) DEFAULT 0,
  total_calories REAL DEFAULT 0,
  rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, user_id, month_start_date)
);

CREATE INDEX IF NOT EXISTS idx_team_leaderboard_weekly_team ON public.team_leaderboard_weekly(team_id, week_start_date);
CREATE INDEX IF NOT EXISTS idx_team_leaderboard_monthly_team ON public.team_leaderboard_monthly(team_id, month_start_date);

-- ============================================================================
-- 4. ENABLE RLS
-- ============================================================================

ALTER TABLE public.team_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaderboard_weekly ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_leaderboard_monthly ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES - TEAM ACTIVITY LOG
-- ============================================================================

-- Users can see activity logs only for teams they belong to
DROP POLICY IF EXISTS "Users can view team activity for their teams" ON public.team_activity_log;
CREATE POLICY "Users can view team activity for their teams" ON public.team_activity_log
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Activity logs are managed by system (triggers), not direct inserts
DROP POLICY IF EXISTS "Only system can insert activity logs" ON public.team_activity_log;
CREATE POLICY "Only system can insert activity logs" ON public.team_activity_log
  FOR INSERT WITH CHECK (FALSE);

-- ============================================================================
-- 6. RLS POLICIES - PROGRAM SUGGESTIONS
-- ============================================================================

-- Users can see suggestions they received
DROP POLICY IF EXISTS "Users can view received suggestions" ON public.program_suggestions;
CREATE POLICY "Users can view received suggestions" ON public.program_suggestions
  FOR SELECT USING (to_user_id = auth.uid());

-- Users can see suggestions they sent
DROP POLICY IF EXISTS "Users can view sent suggestions" ON public.program_suggestions;
CREATE POLICY "Users can view sent suggestions" ON public.program_suggestions
  FOR SELECT USING (from_user_id = auth.uid());

-- Users can create suggestions for team members
DROP POLICY IF EXISTS "Users can send suggestions to team members" ON public.program_suggestions;
CREATE POLICY "Users can send suggestions to team members" ON public.program_suggestions
  FOR INSERT WITH CHECK (
    from_user_id = auth.uid()
    AND to_user_id IN (
      SELECT user_id FROM public.group_members 
      WHERE group_id = team_id 
      AND user_id != auth.uid()
    )
  );

-- Users can update their received suggestions (accept/reject with response)
DROP POLICY IF EXISTS "Users can update received suggestions" ON public.program_suggestions;
CREATE POLICY "Users can update received suggestions" ON public.program_suggestions
  FOR UPDATE USING (to_user_id = auth.uid());

-- ============================================================================
-- 7. RLS POLICIES - LEADERBOARDS
-- ============================================================================

-- Users can view leaderboards only for teams they belong to
DROP POLICY IF EXISTS "Users can view team leaderboards" ON public.team_leaderboard_weekly;
CREATE POLICY "Users can view team leaderboards" ON public.team_leaderboard_weekly
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "Users can view team leaderboards monthly" ON public.team_leaderboard_monthly;
CREATE POLICY "Users can view team leaderboards monthly" ON public.team_leaderboard_monthly
  FOR SELECT USING (
    team_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid())
  );

-- Leaderboards are managed by system (triggers/cron), not direct inserts
DROP POLICY IF EXISTS "Only system can insert leaderboard entries" ON public.team_leaderboard_weekly;
CREATE POLICY "Only system can insert leaderboard entries" ON public.team_leaderboard_weekly
  FOR INSERT WITH CHECK (FALSE);

DROP POLICY IF EXISTS "Only system can insert leaderboard entries monthly" ON public.team_leaderboard_monthly;
CREATE POLICY "Only system can insert leaderboard entries monthly" ON public.team_leaderboard_monthly
  FOR INSERT WITH CHECK (FALSE);

-- ============================================================================
-- 8. TRIGGER FUNCTION: Auto-update activity log from workout_sessions
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_team_activity_log()
RETURNS TRIGGER AS $$
DECLARE
  v_team_id UUID;
  v_date DATE;
BEGIN
  -- Get all teams the user belongs to
  FOR v_team_id IN SELECT group_id FROM public.group_members WHERE user_id = NEW.user_id
  LOOP
    v_date := NEW.date::DATE;
    
    -- Insert or update activity log for each team
    INSERT INTO public.team_activity_log (
      team_id, user_id, activity_date, workouts_count, 
      total_calories, total_duration_minutes, updated_at
    )
    VALUES (
      v_team_id, 
      NEW.user_id, 
      v_date,
      1,
      COALESCE(NEW.calories, 0),
      COALESCE(NEW.duration_minutes, 0),
      NOW()
    )
    ON CONFLICT (team_id, user_id, activity_date) DO UPDATE SET
      workouts_count = team_activity_log.workouts_count + 1,
      total_calories = team_activity_log.total_calories + COALESCE(NEW.calories, 0),
      total_duration_minutes = team_activity_log.total_duration_minutes + COALESCE(NEW.duration_minutes, 0),
      updated_at = NOW();
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Trigger on workout_sessions insert
DROP TRIGGER IF EXISTS trigger_update_team_activity_log ON public.workout_sessions;
CREATE TRIGGER trigger_update_team_activity_log
  AFTER INSERT ON public.workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_team_activity_log();

-- ============================================================================
-- 9. FUNCTION: Refresh leaderboards (called by cron job)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.refresh_team_leaderboards_weekly()
RETURNS void AS $$
DECLARE
  v_week_start_date DATE;
BEGIN
  v_week_start_date := DATE_TRUNC('week', NOW())::DATE;
  
  -- Insert or update weekly leaderboard
  INSERT INTO public.team_leaderboard_weekly (
    team_id, user_id, week_start_date, workout_count, 
    total_calories, rank
  )
  SELECT 
    tal.team_id,
    tal.user_id,
    v_week_start_date,
    SUM(COALESCE(tal.workouts_count, 0)),
    SUM(COALESCE(tal.total_calories, 0)),
    ROW_NUMBER() OVER (PARTITION BY tal.team_id ORDER BY SUM(COALESCE(tal.workouts_count, 0)) DESC, SUM(COALESCE(tal.total_calories, 0)) DESC)
  FROM public.team_activity_log tal
  WHERE tal.activity_date >= v_week_start_date
    AND tal.activity_date < v_week_start_date + INTERVAL '7 days'
  GROUP BY tal.team_id, tal.user_id
  ON CONFLICT (team_id, user_id, week_start_date) DO UPDATE SET
    workout_count = EXCLUDED.workout_count,
    total_calories = EXCLUDED.total_calories,
    rank = EXCLUDED.rank,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.refresh_team_leaderboards_monthly()
RETURNS void AS $$
DECLARE
  v_month_start_date DATE;
BEGIN
  v_month_start_date := DATE_TRUNC('month', NOW())::DATE;
  
  -- Insert or update monthly leaderboard
  INSERT INTO public.team_leaderboard_monthly (
    team_id, user_id, month_start_date, workout_count, 
    total_calories, rank
  )
  SELECT 
    tal.team_id,
    tal.user_id,
    v_month_start_date,
    SUM(COALESCE(tal.workouts_count, 0)),
    SUM(COALESCE(tal.total_calories, 0)),
    ROW_NUMBER() OVER (PARTITION BY tal.team_id ORDER BY SUM(COALESCE(tal.workouts_count, 0)) DESC, SUM(COALESCE(tal.total_calories, 0)) DESC)
  FROM public.team_activity_log tal
  WHERE tal.activity_date >= v_month_start_date
    AND tal.activity_date < v_month_start_date + INTERVAL '1 month'
  GROUP BY tal.team_id, tal.user_id
  ON CONFLICT (team_id, user_id, month_start_date) DO UPDATE SET
    workout_count = EXCLUDED.workout_count,
    total_calories = EXCLUDED.total_calories,
    rank = EXCLUDED.rank,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Note: To enable automatic refresh, run in Supabase dashboard:
-- SELECT cron.schedule('refresh_team_leaderboards_weekly', '0 1 * * 1', 'SELECT public.refresh_team_leaderboards_weekly()');
-- SELECT cron.schedule('refresh_team_leaderboards_monthly', '0 1 1 * *', 'SELECT public.refresh_team_leaderboards_monthly()');
