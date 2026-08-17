-- Invariant suite. Run after schema, commands, and seed data.
SET search_path = social, public;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM follows WHERE follower_id=followed_id) THEN RAISE EXCEPTION 'self follow'; END IF;
  IF EXISTS(SELECT 1 FROM blocks WHERE blocker_id=blocked_id) THEN RAISE EXCEPTION 'self block'; END IF;
  IF EXISTS(
      SELECT 1 FROM follows f JOIN blocks b
      ON (b.blocker_id=f.follower_id AND b.blocked_id=f.followed_id)
      OR (b.blocker_id=f.followed_id AND b.blocked_id=f.follower_id)
  ) THEN RAISE EXCEPTION 'blocked pair still follows'; END IF;
  IF EXISTS(SELECT 1 FROM feed_items fi WHERE NOT can_view_post(fi.owner_user_id,fi.post_id))
     THEN RAISE EXCEPTION 'invisible feed item'; END IF;
  IF EXISTS(SELECT 1 FROM reactions GROUP BY user_id,post_id HAVING count(*)>1)
     THEN RAISE EXCEPTION 'duplicate reaction'; END IF;
  IF EXISTS(
      SELECT 1 FROM post_counters pc
      WHERE pc.reaction_count<>(SELECT count(*) FROM reactions r WHERE r.post_id=pc.post_id)
  ) THEN RAISE EXCEPTION 'counter drift'; END IF;
  IF EXISTS(SELECT 1 FROM notifications GROUP BY recipient_id,dedupe_key HAVING count(*)>1)
     THEN RAISE EXCEPTION 'duplicate notification'; END IF;
END $$;
