-- Small deterministic dataset for demonstrations
SET search_path = social, public;
INSERT INTO users(handle,normalized_handle,email_hash,state,is_private) VALUES
('Aarav','aarav',repeat('a',64),'ACTIVE',false),
('Diya','diya',repeat('b',64),'ACTIVE',true),
('Kabir','kabir',repeat('c',64),'ACTIVE',false),
('Meera','meera',repeat('d',64),'ACTIVE',false),
('Rohan','rohan',repeat('e',64),'ACTIVE',false);
INSERT INTO profiles(user_id,display_name,bio_text)
SELECT user_id,initcap(handle),handle||' explores SQL systems.' FROM users;
INSERT INTO follows(follower_id,followed_id,state,accepted_at) VALUES
(1,2,'ACCEPTED',clock_timestamp()),(1,3,'ACCEPTED',clock_timestamp()),
(2,3,'ACCEPTED',clock_timestamp()),(3,4,'ACCEPTED',clock_timestamp()),
(4,1,'ACCEPTED',clock_timestamp());
INSERT INTO posts(author_id,state,visibility,body_text,published_at) VALUES
(2,'PUBLISHED','FOLLOWERS','Private-account update for accepted followers.',clock_timestamp()-interval '3 hour'),
(3,'PUBLISHED','PUBLIC','Keyset pagination needs a stable unique tie-breaker.',clock_timestamp()-interval '2 hour'),
(4,'PUBLISHED','PUBLIC','A feed is a policy result, not merely a timestamp sort.',clock_timestamp()-interval '1 hour');
INSERT INTO post_counters(post_id) SELECT post_id FROM posts;
