-- Relationship, privacy, publication, and idempotency commands
SET search_path = social, public;

CREATE OR REPLACE FUNCTION is_blocked(p_left BIGINT, p_right BIGINT)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = p_left AND blocked_id = p_right)
           OR (blocker_id = p_right AND blocked_id = p_left)
    );
$$;

CREATE OR REPLACE FUNCTION can_view_post(p_viewer BIGINT, p_post BIGINT)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = social, pg_temp AS $$
    SELECT EXISTS (
        SELECT 1
        FROM posts p
        JOIN users a ON a.user_id = p.author_id
        WHERE p.post_id = p_post
          AND p.state = 'PUBLISHED'
          AND a.state = 'ACTIVE'
          AND NOT is_blocked(p_viewer, p.author_id)
          AND (
              p.author_id = p_viewer
              OR p.visibility = 'PUBLIC'
              OR (p.visibility = 'FOLLOWERS' AND EXISTS (
                    SELECT 1 FROM follows f
                    WHERE f.follower_id = p_viewer
                      AND f.followed_id = p.author_id
                      AND f.state = 'ACCEPTED'))
              OR (p.visibility = 'CUSTOM' AND EXISTS (
                    SELECT 1 FROM post_custom_audience ca
                    WHERE ca.post_id = p.post_id
                      AND ca.viewer_user_id = p_viewer))
          )
    );
$$;

CREATE OR REPLACE FUNCTION request_follow(
    p_actor BIGINT, p_target BIGINT, p_command UUID,
    p_idempotency_key TEXT, p_request_hash CHAR(64)
) RETURNS follow_state LANGUAGE plpgsql AS $$
DECLARE v_existing command_requests%ROWTYPE; v_private BOOLEAN; v_state follow_state;
BEGIN
    IF p_actor = p_target THEN RAISE EXCEPTION 'cannot follow self'; END IF;
    PERFORM pg_advisory_xact_lock(least(p_actor,p_target), greatest(p_actor,p_target));
    IF is_blocked(p_actor,p_target) THEN RAISE EXCEPTION 'relationship blocked'; END IF;

    INSERT INTO command_requests(command_id,actor_user_id,command_type,idempotency_key,request_hash)
    VALUES (p_command,p_actor,'FOLLOW',p_idempotency_key,p_request_hash)
    ON CONFLICT (actor_user_id,command_type,idempotency_key) DO NOTHING;

    SELECT * INTO v_existing FROM command_requests
    WHERE actor_user_id=p_actor AND command_type='FOLLOW' AND idempotency_key=p_idempotency_key
    FOR UPDATE;
    IF v_existing.request_hash <> p_request_hash THEN
        RAISE EXCEPTION 'idempotency key reused with different request';
    END IF;
    IF v_existing.status='SUCCEEDED' THEN
        SELECT state INTO v_state FROM follows WHERE follower_id=p_actor AND followed_id=p_target;
        RETURN v_state;
    END IF;

    SELECT is_private INTO v_private FROM users WHERE user_id=p_target AND state='ACTIVE';
    IF NOT FOUND THEN RAISE EXCEPTION 'target unavailable'; END IF;
    v_state := CASE WHEN v_private THEN 'PENDING'::follow_state ELSE 'ACCEPTED'::follow_state END;

    INSERT INTO follows(follower_id,followed_id,state,accepted_at)
    VALUES (p_actor,p_target,v_state,CASE WHEN v_state='ACCEPTED' THEN clock_timestamp() END)
    ON CONFLICT (follower_id,followed_id) DO UPDATE
       SET state=EXCLUDED.state, accepted_at=EXCLUDED.accepted_at,
           version_no=follows.version_no+1;

    UPDATE command_requests SET status='SUCCEEDED',completed_at=clock_timestamp()
    WHERE command_id=v_existing.command_id;
    RETURN v_state;
END $$;

CREATE OR REPLACE FUNCTION block_user(p_blocker BIGINT, p_blocked BIGINT, p_reason TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    IF p_blocker=p_blocked THEN RAISE EXCEPTION 'cannot block self'; END IF;
    PERFORM pg_advisory_xact_lock(least(p_blocker,p_blocked), greatest(p_blocker,p_blocked));
    INSERT INTO blocks(blocker_id,blocked_id,reason_code)
    VALUES (p_blocker,p_blocked,p_reason)
    ON CONFLICT (blocker_id,blocked_id) DO NOTHING;
    DELETE FROM follows
    WHERE (follower_id=p_blocker AND followed_id=p_blocked)
       OR (follower_id=p_blocked AND followed_id=p_blocker);
    DELETE FROM feed_items
    WHERE (owner_user_id=p_blocker AND source_author_id=p_blocked)
       OR (owner_user_id=p_blocked AND source_author_id=p_blocker);
END $$;

CREATE OR REPLACE FUNCTION publish_post(
    p_author BIGINT, p_body TEXT, p_visibility post_visibility,
    p_command UUID, p_idempotency_key TEXT, p_request_hash CHAR(64)
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_cmd command_requests%ROWTYPE; v_post BIGINT;
BEGIN
    INSERT INTO command_requests(command_id,actor_user_id,command_type,idempotency_key,request_hash)
    VALUES (p_command,p_author,'PUBLISH_POST',p_idempotency_key,p_request_hash)
    ON CONFLICT (actor_user_id,command_type,idempotency_key) DO NOTHING;
    SELECT * INTO v_cmd FROM command_requests
    WHERE actor_user_id=p_author AND command_type='PUBLISH_POST' AND idempotency_key=p_idempotency_key
    FOR UPDATE;
    IF v_cmd.request_hash<>p_request_hash THEN RAISE EXCEPTION 'idempotency conflict'; END IF;
    IF v_cmd.status='SUCCEEDED' THEN RETURN v_cmd.result_object_id; END IF;

    INSERT INTO posts(author_id,state,visibility,body_text,published_at)
    VALUES (p_author,'PUBLISHED',p_visibility,p_body,clock_timestamp()) RETURNING post_id INTO v_post;
    INSERT INTO post_counters(post_id) VALUES(v_post);
    INSERT INTO outbox_events(event_id,aggregate_type,aggregate_id,event_type,payload_json)
    VALUES (gen_random_uuid(),'POST',v_post,'POST_PUBLISHED',jsonb_build_object('post_id',v_post,'author_id',p_author));
    UPDATE command_requests SET status='SUCCEEDED',result_object_type='POST',
        result_object_id=v_post,completed_at=clock_timestamp() WHERE command_id=v_cmd.command_id;
    RETURN v_post;
END $$;

CREATE OR REPLACE FUNCTION add_reaction(p_user BIGINT,p_post BIGINT,p_kind reaction_kind)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_inserted INTEGER;
BEGIN
    IF NOT can_view_post(p_user,p_post) THEN RAISE EXCEPTION 'post not visible'; END IF;
    INSERT INTO reactions(user_id,post_id,kind) VALUES(p_user,p_post,p_kind)
    ON CONFLICT (user_id,post_id) DO UPDATE SET kind=EXCLUDED.kind;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    INSERT INTO post_counters(post_id,reaction_count) VALUES(p_post,1)
    ON CONFLICT(post_id) DO UPDATE SET reaction_count=(SELECT count(*) FROM reactions WHERE post_id=p_post),
        updated_at=clock_timestamp();
END $$;
