-- SQL Full Mastery - Part 110
-- Social Platform Feed and Relationship Queries
-- Primary target: PostgreSQL 15+
-- Author: Ram Sandesh

BEGIN;
CREATE SCHEMA IF NOT EXISTS social;
SET search_path = social, public;

CREATE TYPE user_state AS ENUM ('PENDING','ACTIVE','SUSPENDED','DELETED');
CREATE TYPE follow_state AS ENUM ('PENDING','ACCEPTED','REJECTED');
CREATE TYPE post_visibility AS ENUM ('PUBLIC','FOLLOWERS','PRIVATE','CUSTOM');
CREATE TYPE post_state AS ENUM ('DRAFT','PUBLISHED','HIDDEN','DELETED');
CREATE TYPE reaction_kind AS ENUM ('LIKE','LOVE','CELEBRATE','INSIGHTFUL');
CREATE TYPE moderation_state AS ENUM ('OPEN','REVIEWING','ACTIONED','DISMISSED');
CREATE TYPE notification_state AS ENUM ('PENDING','SENT','FAILED','SUPPRESSED');

CREATE TABLE users (
    user_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    handle           VARCHAR(32) NOT NULL,
    normalized_handle VARCHAR(32) NOT NULL,
    email_hash       CHAR(64) NOT NULL,
    state            user_state NOT NULL DEFAULT 'PENDING',
    is_private       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMPTZ,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    CHECK (normalized_handle = lower(normalized_handle)),
    CHECK (deleted_at IS NULL OR state = 'DELETED'),
    UNIQUE (normalized_handle),
    UNIQUE (email_hash)
);

CREATE TABLE profiles (
    user_id          BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    display_name     VARCHAR(100) NOT NULL,
    bio_text         VARCHAR(500),
    avatar_key       VARCHAR(240),
    location_text    VARCHAR(120),
    website_url      VARCHAR(500),
    profile_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    search_vector    TSVECTOR GENERATED ALWAYS AS
        (to_tsvector('simple', coalesce(display_name,'') || ' ' || coalesce(bio_text,''))) STORED
);

CREATE TABLE follows (
    follower_id      BIGINT NOT NULL REFERENCES users(user_id),
    followed_id      BIGINT NOT NULL REFERENCES users(user_id),
    state            follow_state NOT NULL,
    requested_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at      TIMESTAMPTZ,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    PRIMARY KEY (follower_id, followed_id),
    CHECK (follower_id <> followed_id),
    CHECK ((state = 'ACCEPTED' AND accepted_at IS NOT NULL)
        OR (state <> 'ACCEPTED'))
);

CREATE TABLE blocks (
    blocker_id       BIGINT NOT NULL REFERENCES users(user_id),
    blocked_id       BIGINT NOT NULL REFERENCES users(user_id),
    reason_code      VARCHAR(40),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);

CREATE TABLE mutes (
    muter_id         BIGINT NOT NULL REFERENCES users(user_id),
    muted_id         BIGINT NOT NULL REFERENCES users(user_id),
    expires_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (muter_id, muted_id),
    CHECK (muter_id <> muted_id)
);

CREATE TABLE command_requests (
    command_id       UUID PRIMARY KEY,
    actor_user_id    BIGINT NOT NULL REFERENCES users(user_id),
    command_type     VARCHAR(50) NOT NULL,
    idempotency_key  VARCHAR(160) NOT NULL,
    request_hash     CHAR(64) NOT NULL,
    status           VARCHAR(16) NOT NULL DEFAULT 'STARTED'
                     CHECK (status IN ('STARTED','SUCCEEDED','FAILED')),
    result_object_type VARCHAR(40),
    result_object_id BIGINT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at     TIMESTAMPTZ,
    UNIQUE (actor_user_id, command_type, idempotency_key)
);

CREATE TABLE posts (
    post_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_id        BIGINT NOT NULL REFERENCES users(user_id),
    state            post_state NOT NULL DEFAULT 'DRAFT',
    visibility       post_visibility NOT NULL DEFAULT 'PUBLIC',
    body_text        VARCHAR(5000) NOT NULL,
    reply_to_post_id BIGINT REFERENCES posts(post_id),
    quote_post_id    BIGINT REFERENCES posts(post_id),
    published_at     TIMESTAMPTZ,
    edited_at        TIMESTAMPTZ,
    deleted_at       TIMESTAMPTZ,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    search_vector    TSVECTOR GENERATED ALWAYS AS
        (to_tsvector('simple', coalesce(body_text,''))) STORED,
    CHECK ((state = 'PUBLISHED' AND published_at IS NOT NULL)
        OR state <> 'PUBLISHED'),
    CHECK (reply_to_post_id IS NULL OR reply_to_post_id <> post_id),
    CHECK (quote_post_id IS NULL OR quote_post_id <> post_id)
);

CREATE TABLE post_custom_audience (
    post_id          BIGINT NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    viewer_user_id   BIGINT NOT NULL REFERENCES users(user_id),
    PRIMARY KEY (post_id, viewer_user_id)
);

CREATE TABLE post_media (
    media_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id          BIGINT NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    position_no      SMALLINT NOT NULL CHECK (position_no > 0),
    object_key       VARCHAR(300) NOT NULL,
    media_type       VARCHAR(24) NOT NULL CHECK (media_type IN ('IMAGE','VIDEO','AUDIO','DOCUMENT')),
    alt_text         VARCHAR(500),
    width_px         INTEGER CHECK (width_px > 0),
    height_px        INTEGER CHECK (height_px > 0),
    UNIQUE (post_id, position_no)
);

CREATE TABLE comments (
    comment_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id          BIGINT NOT NULL REFERENCES posts(post_id),
    author_id        BIGINT NOT NULL REFERENCES users(user_id),
    parent_comment_id BIGINT REFERENCES comments(comment_id),
    body_text        VARCHAR(2000) NOT NULL,
    state            VARCHAR(16) NOT NULL DEFAULT 'VISIBLE'
                     CHECK (state IN ('VISIBLE','HIDDEN','DELETED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    edited_at        TIMESTAMPTZ,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    CHECK (parent_comment_id IS NULL OR parent_comment_id <> comment_id)
);

CREATE TABLE reactions (
    user_id          BIGINT NOT NULL REFERENCES users(user_id),
    post_id          BIGINT NOT NULL REFERENCES posts(post_id),
    kind             reaction_kind NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id)
);

CREATE TABLE post_counters (
    post_id          BIGINT PRIMARY KEY REFERENCES posts(post_id) ON DELETE CASCADE,
    reaction_count   BIGINT NOT NULL DEFAULT 0 CHECK (reaction_count >= 0),
    comment_count    BIGINT NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
    repost_count     BIGINT NOT NULL DEFAULT 0 CHECK (repost_count >= 0),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE feed_items (
    owner_user_id    BIGINT NOT NULL REFERENCES users(user_id),
    post_id          BIGINT NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    source_author_id BIGINT NOT NULL REFERENCES users(user_id),
    reason_code      VARCHAR(24) NOT NULL CHECK (reason_code IN ('FOLLOW','SELF','RECOMMENDED')),
    ranked_at        TIMESTAMPTZ NOT NULL,
    score_value      NUMERIC(18,6) NOT NULL DEFAULT 0,
    inserted_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (owner_user_id, post_id)
);

CREATE TABLE moderation_reports (
    report_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reporter_id      BIGINT NOT NULL REFERENCES users(user_id),
    object_type      VARCHAR(24) NOT NULL CHECK (object_type IN ('USER','POST','COMMENT')),
    object_id        BIGINT NOT NULL,
    reason_code      VARCHAR(40) NOT NULL,
    details_text     VARCHAR(1000),
    state            moderation_state NOT NULL DEFAULT 'OPEN',
    assigned_to      BIGINT REFERENCES users(user_id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at      TIMESTAMPTZ,
    UNIQUE (reporter_id, object_type, object_id, reason_code)
);

CREATE TABLE moderation_actions (
    action_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id        BIGINT REFERENCES moderation_reports(report_id),
    moderator_id     BIGINT NOT NULL REFERENCES users(user_id),
    action_code      VARCHAR(40) NOT NULL,
    object_type      VARCHAR(24) NOT NULL,
    object_id        BIGINT NOT NULL,
    reason_text      VARCHAR(1000) NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    notification_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipient_id    BIGINT NOT NULL REFERENCES users(user_id),
    actor_id        BIGINT REFERENCES users(user_id),
    event_type      VARCHAR(40) NOT NULL,
    object_type     VARCHAR(24) NOT NULL,
    object_id       BIGINT NOT NULL,
    state           notification_state NOT NULL DEFAULT 'PENDING',
    dedupe_key      VARCHAR(200) NOT NULL,
    payload_json    JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at         TIMESTAMPTZ,
    UNIQUE (recipient_id, dedupe_key)
);

CREATE TABLE audit_events (
    audit_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_user_id    BIGINT REFERENCES users(user_id),
    action_code      VARCHAR(80) NOT NULL,
    object_type      VARCHAR(40) NOT NULL,
    object_id        BIGINT,
    request_id       UUID,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details_json     JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE outbox_events (
    event_id         UUID PRIMARY KEY,
    aggregate_type   VARCHAR(40) NOT NULL,
    aggregate_id     BIGINT NOT NULL,
    event_type       VARCHAR(80) NOT NULL,
    payload_json     JSONB NOT NULL,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at     TIMESTAMPTZ,
    attempt_count    INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ix_follows_followed_accepted
    ON follows (followed_id, follower_id) WHERE state = 'ACCEPTED';
CREATE INDEX ix_follows_follower_accepted
    ON follows (follower_id, followed_id) WHERE state = 'ACCEPTED';
CREATE INDEX ix_blocks_blocked ON blocks (blocked_id, blocker_id);
CREATE INDEX ix_posts_author_timeline
    ON posts (author_id, published_at DESC, post_id DESC) WHERE state = 'PUBLISHED';
CREATE INDEX ix_posts_public_timeline
    ON posts (published_at DESC, post_id DESC)
    WHERE state = 'PUBLISHED' AND visibility = 'PUBLIC';
CREATE INDEX ix_comments_post_page
    ON comments (post_id, created_at, comment_id) WHERE state = 'VISIBLE';
CREATE INDEX ix_feed_owner_page
    ON feed_items (owner_user_id, ranked_at DESC, post_id DESC);
CREATE INDEX ix_notifications_pending
    ON notifications (recipient_id, created_at DESC, notification_id DESC)
    WHERE state = 'PENDING';
CREATE INDEX ix_reports_queue
    ON moderation_reports (state, created_at, report_id)
    WHERE state IN ('OPEN','REVIEWING');
CREATE INDEX ix_profiles_search ON profiles USING GIN (search_vector);
CREATE INDEX ix_posts_search ON posts USING GIN (search_vector);
CREATE INDEX ix_outbox_ready
    ON outbox_events (next_attempt_at, occurred_at, event_id)
    WHERE published_at IS NULL;

COMMIT;
