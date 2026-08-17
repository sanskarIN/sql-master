-- Feed generation, keyset pagination, relationship and graph queries
SET search_path = social, public;

-- Fan-out-on-write worker for ordinary authors. A production worker processes
-- POST_PUBLISHED outbox events in bounded batches and calls this statement.
INSERT INTO feed_items(owner_user_id,post_id,source_author_id,reason_code,ranked_at,score_value)
SELECT f.follower_id, p.post_id, p.author_id, 'FOLLOW', p.published_at, 1.0
FROM posts p
JOIN follows f ON f.followed_id=p.author_id AND f.state='ACCEPTED'
LEFT JOIN blocks b1 ON b1.blocker_id=f.follower_id AND b1.blocked_id=p.author_id
LEFT JOIN blocks b2 ON b2.blocker_id=p.author_id AND b2.blocked_id=f.follower_id
LEFT JOIN mutes m ON m.muter_id=f.follower_id AND m.muted_id=p.author_id
WHERE p.post_id=:post_id AND b1.blocker_id IS NULL AND b2.blocker_id IS NULL
  AND (m.muter_id IS NULL OR m.expires_at <= clock_timestamp())
ON CONFLICT(owner_user_id,post_id) DO NOTHING;

-- Home feed page: deterministic keyset boundary, visibility re-check, no OFFSET.
SELECT fi.post_id, fi.source_author_id, p.body_text, p.published_at,
       pc.reaction_count, pc.comment_count
FROM feed_items fi
JOIN posts p ON p.post_id=fi.post_id
LEFT JOIN post_counters pc ON pc.post_id=p.post_id
WHERE fi.owner_user_id=:viewer_id
  AND can_view_post(:viewer_id,fi.post_id)
  AND (fi.ranked_at,fi.post_id) < (:cursor_ranked_at,:cursor_post_id)
ORDER BY fi.ranked_at DESC,fi.post_id DESC
LIMIT :page_size;

-- Fan-out-on-read path for high-fanout authors or newly followed accounts.
SELECT p.post_id,p.author_id,p.body_text,p.published_at
FROM follows f
JOIN posts p ON p.author_id=f.followed_id
WHERE f.follower_id=:viewer_id AND f.state='ACCEPTED'
  AND p.state='PUBLISHED'
  AND can_view_post(:viewer_id,p.post_id)
  AND (p.published_at,p.post_id) < (:cursor_time,:cursor_post_id)
ORDER BY p.published_at DESC,p.post_id DESC
LIMIT :page_size;

-- Mutual-follow suggestions with privacy/block exclusions.
WITH mine AS (
  SELECT followed_id FROM follows WHERE follower_id=:viewer_id AND state='ACCEPTED'
), candidates AS (
  SELECT f.followed_id AS candidate_id,count(*) AS mutual_count
  FROM follows f JOIN mine m ON m.followed_id=f.follower_id
  WHERE f.state='ACCEPTED' AND f.followed_id<>:viewer_id
  GROUP BY f.followed_id
)
SELECT c.candidate_id,p.display_name,c.mutual_count
FROM candidates c JOIN profiles p ON p.user_id=c.candidate_id
WHERE NOT EXISTS (SELECT 1 FROM follows x WHERE x.follower_id=:viewer_id AND x.followed_id=c.candidate_id)
  AND NOT is_blocked(:viewer_id,c.candidate_id)
ORDER BY c.mutual_count DESC,c.candidate_id
LIMIT :limit;

-- Shortest visible relationship path with a strict depth bound.
WITH RECURSIVE graph(user_id,path,depth) AS (
  SELECT :start_user,ARRAY[:start_user]::BIGINT[],0
  UNION ALL
  SELECT f.followed_id,g.path||f.followed_id,g.depth+1
  FROM graph g JOIN follows f ON f.follower_id=g.user_id AND f.state='ACCEPTED'
  WHERE g.depth<4 AND NOT f.followed_id=ANY(g.path)
    AND NOT is_blocked(:viewer_id,f.followed_id)
)
SELECT path,depth FROM graph WHERE user_id=:target_user ORDER BY depth LIMIT 1;

-- Search requires visibility after candidate retrieval.
SELECT p.post_id,p.author_id,p.body_text,p.published_at,
       ts_rank_cd(p.search_vector,websearch_to_tsquery('simple',:query)) AS rank
FROM posts p
WHERE p.search_vector @@ websearch_to_tsquery('simple',:query)
  AND can_view_post(:viewer_id,p.post_id)
ORDER BY rank DESC,p.published_at DESC,p.post_id DESC
LIMIT :limit;
