-- ============================================================================
-- Team (group) layer fixes
-- ----------------------------------------------------------------------------
-- The Flutter client's TeamProvider reads and writes columns and performs
-- operations that the original social bootstrap (supabase_schema.sql) never
-- granted. Without this migration every team feature fails at runtime:
--
--   1. `groups` had no `description` / `owner_id` columns, but createTeam()
--      inserts both and Team.fromJson() reads both.
--   2. The `group_members` SELECT policy selected from `group_members`, so
--      evaluating it re-entered itself -> infinite recursion (42P17).
--   3. There were no INSERT/UPDATE/DELETE policies at all on `groups` or
--      `group_members`, so creating a team, joining, leaving, removing a
--      member and deleting a team were all rejected.
--   4. Joining by invite token needed to SELECT a group the user is not yet a
--      member of, which the SELECT policy forbids. Loosening that policy would
--      let anyone enumerate every group, so the join goes through a
--      SECURITY DEFINER RPC that validates the token instead.
--   5. `user_blocks` / `user_reports` had RLS enabled but no policies, so
--      blocking and reporting always failed.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Missing columns
-- ----------------------------------------------------------------------------

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Existing groups predate owner_id; adopt the earliest admin as the owner.
UPDATE public.groups g
SET owner_id = m.user_id
FROM (
  SELECT DISTINCT ON (group_id) group_id, user_id
  FROM public.group_members
  WHERE role = 'admin'
  ORDER BY group_id, joined_at
) m
WHERE g.owner_id IS NULL
  AND m.group_id = g.id;

CREATE INDEX IF NOT EXISTS group_members_user_id_idx
  ON public.group_members (user_id);

-- ----------------------------------------------------------------------------
-- 2. Membership helpers
--
-- SECURITY DEFINER on purpose: a policy on `group_members` that queries
-- `group_members` directly would re-evaluate that same policy and recurse.
-- Running the lookup as the definer skips policy evaluation and terminates.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_team_member(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_team_admin(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id = auth.uid()
      AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

CREATE OR REPLACE FUNCTION public.is_group_owner(p_group_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = p_group_id
      AND owner_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.is_team_member(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_team_admin(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_group_owner(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_team_member(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_team_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_group_owner(UUID) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. `groups` policies
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view groups they belong to" ON public.groups;

-- The owner is included so that the INSERT ... RETURNING of createTeam() can
-- read back the row it just wrote, before the first membership row exists.
CREATE POLICY "Users can view groups they belong to" ON public.groups
  FOR SELECT TO authenticated
  USING (public.is_team_member(id) OR owner_id = auth.uid());

DROP POLICY IF EXISTS "Users can create groups" ON public.groups;
CREATE POLICY "Users can create groups" ON public.groups
  FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Admins can update their group" ON public.groups;
CREATE POLICY "Admins can update their group" ON public.groups
  FOR UPDATE TO authenticated
  USING (public.is_team_admin(id) OR owner_id = auth.uid())
  WITH CHECK (public.is_team_admin(id) OR owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can delete their group" ON public.groups;
CREATE POLICY "Owners can delete their group" ON public.groups
  FOR DELETE TO authenticated
  USING (owner_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 4. `group_members` policies
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view members of their groups" ON public.group_members;

CREATE POLICY "Users can view members of their groups" ON public.group_members
  FOR SELECT TO authenticated
  USING (public.is_team_member(group_id));

-- Direct self-insert is limited to the group's own creator. Everyone else
-- joins through join_team_by_invite_token(), which proves they hold a valid
-- token; otherwise knowing a group's UUID would be enough to walk in.
DROP POLICY IF EXISTS "Owners can add themselves to their group" ON public.group_members;
CREATE POLICY "Owners can add themselves to their group" ON public.group_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND public.is_group_owner(group_id));

DROP POLICY IF EXISTS "Members can leave and admins can remove" ON public.group_members;
CREATE POLICY "Members can leave and admins can remove" ON public.group_members
  FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.is_team_admin(group_id));

DROP POLICY IF EXISTS "Admins can change member roles" ON public.group_members;
CREATE POLICY "Admins can change member roles" ON public.group_members
  FOR UPDATE TO authenticated
  USING (public.is_team_admin(group_id))
  WITH CHECK (public.is_team_admin(group_id));

-- ----------------------------------------------------------------------------
-- 5. Join by invite token
--
-- Returns the joined group. Raises:
--   P0002 - no group carries that token
--   P0001 - the caller is already a member
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.join_team_by_invite_token(p_token TEXT)
RETURNS public.groups AS $$
DECLARE
  v_group public.groups;
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_group
  FROM public.groups
  WHERE invite_token = upper(btrim(p_token));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid invite code' USING ERRCODE = 'P0002';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = v_group.id
      AND user_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Already a member of this team' USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.group_members (group_id, user_id, role, joined_at)
  VALUES (v_group.id, v_uid, 'member', NOW());

  RETURN v_group;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '';

REVOKE ALL ON FUNCTION public.join_team_by_invite_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_team_by_invite_token(TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Blocks and reports
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users manage their own blocks" ON public.user_blocks;
CREATE POLICY "Users manage their own blocks" ON public.user_blocks
  FOR ALL TO authenticated
  USING (blocker_id = auth.uid())
  WITH CHECK (blocker_id = auth.uid());

DROP POLICY IF EXISTS "Users can file reports" ON public.user_reports;
CREATE POLICY "Users can file reports" ON public.user_reports
  FOR INSERT TO authenticated
  WITH CHECK (reporter_id = auth.uid());

DROP POLICY IF EXISTS "Users can read their own reports" ON public.user_reports;
CREATE POLICY "Users can read their own reports" ON public.user_reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

COMMIT;
