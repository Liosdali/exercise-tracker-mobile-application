-- Adds each team's kit colour.
--
-- The column stores a slug, not a hex value. Light and dark transforms live
-- in the client (lib/theme/team_palette.dart), and the CHECK constraint stops
-- a team setting itself to something unreadable.
--
-- Re-runnable: every statement guards itself, matching the convention
-- established in 202609160001.

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT 'steel';

ALTER TABLE public.groups
  DROP CONSTRAINT IF EXISTS groups_color_check;

ALTER TABLE public.groups
  ADD CONSTRAINT groups_color_check
  CHECK (color IN (
    'crimson', 'claret', 'violet', 'royal',
    'teal', 'forest', 'gold', 'steel'
  ));

COMMENT ON COLUMN public.groups.color IS
  'Kit colour slug; resolved to hex per scheme by the Flutter client.';
