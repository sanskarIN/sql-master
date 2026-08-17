-- Moderation, notifications, counters, security, and operations
SET search_path = social, public;

-- Claim reports with SKIP LOCKED so several workers can share one queue.
WITH claimed AS (
  SELECT report_id FROM moderation_reports
  WHERE state='OPEN' ORDER BY created_at,report_id
  FOR UPDATE SKIP LOCKED LIMIT :batch_size
)
UPDATE moderation_reports r SET state='REVIEWING',assigned_to=:moderator_id
FROM claimed c WHERE r.report_id=c.report_id
RETURNING r.*;

-- Notification insert is deduplicated by recipient and event identity.
INSERT INTO notifications(recipient_id,actor_id,event_type,object_type,object_id,dedupe_key,payload_json)
VALUES (:recipient_id,:actor_id,:event_type,:object_type,:object_id,
        :event_type||':'||:object_type||':'||:object_id||':'||coalesce(:actor_id::text,'system'),:payload)
ON CONFLICT(recipient_id,dedupe_key) DO NOTHING;

-- Reconcile eventually consistent counters against authoritative base rows.
UPDATE post_counters pc
SET reaction_count=x.reactions,comment_count=x.comments,updated_at=clock_timestamp()
FROM (
  SELECT p.post_id,
    (SELECT count(*) FROM reactions r WHERE r.post_id=p.post_id) AS reactions,
    (SELECT count(*) FROM comments c WHERE c.post_id=p.post_id AND c.state='VISIBLE') AS comments
  FROM posts p WHERE p.post_id BETWEEN :min_post AND :max_post
) x WHERE pc.post_id=x.post_id
  AND (pc.reaction_count,pc.comment_count) IS DISTINCT FROM (x.reactions,x.comments);

-- Optional RLS boundary: application sets app.user_id per transaction.
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY post_read_policy ON posts FOR SELECT
USING (can_view_post(current_setting('app.user_id',true)::BIGINT,post_id));

-- Operational evidence queries.
SELECT count(*) AS pending_events,min(occurred_at) AS oldest_event
FROM outbox_events WHERE published_at IS NULL;

SELECT count(*) AS open_reports,min(created_at) AS oldest_report
FROM moderation_reports WHERE state IN ('OPEN','REVIEWING');

SELECT owner_user_id,count(*) AS feed_rows,min(ranked_at) AS oldest_ranked_at
FROM feed_items GROUP BY owner_user_id ORDER BY count(*) DESC LIMIT 20;

SELECT p.post_id,pc.reaction_count,count(r.user_id) AS authoritative
FROM posts p JOIN post_counters pc USING(post_id)
LEFT JOIN reactions r USING(post_id)
GROUP BY p.post_id,pc.reaction_count
HAVING pc.reaction_count<>count(r.user_id)
ORDER BY abs(pc.reaction_count-count(r.user_id)) DESC LIMIT 100;
