SET search_path = lab, public;

-- Q8. Sessionize with a strict rule: a new session starts when the gap is >= 30 minutes.
WITH ordered AS (
  SELECT e.*,
         LAG(event_time) OVER (
           PARTITION BY account_id,user_id
           ORDER BY event_time,event_id
         ) AS previous_time
  FROM event_log e
), marked AS (
  SELECT ordered.*,
         CASE WHEN previous_time IS NULL
                    OR event_time - previous_time >= interval '30 minutes'
              THEN 1 ELSE 0 END AS starts_session
  FROM ordered
), numbered AS (
  SELECT marked.*,
         SUM(starts_session) OVER (
           PARTITION BY account_id,user_id
           ORDER BY event_time,event_id
           ROWS UNBOUNDED PRECEDING
         ) AS session_no
  FROM marked
)
SELECT account_id,user_id,session_no,
       MIN(event_time) AS session_start,
       MAX(event_time) AS session_end,
       COUNT(*) AS event_count
FROM numbered
GROUP BY account_id,user_id,session_no
ORDER BY account_id,user_id,session_no;

-- Q9. Ordered funnel within seven days of signup. Each step must occur after the prior step.
WITH signup AS (
  SELECT account_id,user_id,MIN(event_time) AS signup_time
  FROM event_log WHERE event_name='signup' GROUP BY account_id,user_id
), steps AS (
  SELECT s.*,
         v.view_time,
         c.cart_time,
         p.purchase_time
  FROM signup s
  LEFT JOIN LATERAL (
    SELECT MIN(event_time) view_time FROM event_log e
    WHERE e.account_id=s.account_id AND e.user_id=s.user_id
      AND e.event_name='view'
      AND e.event_time >= s.signup_time
      AND e.event_time < s.signup_time + interval '7 days'
  ) v ON true
  LEFT JOIN LATERAL (
    SELECT MIN(event_time) cart_time FROM event_log e
    WHERE e.account_id=s.account_id AND e.user_id=s.user_id
      AND e.event_name='add_to_cart'
      AND e.event_time >= v.view_time
      AND e.event_time < s.signup_time + interval '7 days'
  ) c ON v.view_time IS NOT NULL
  LEFT JOIN LATERAL (
    SELECT MIN(event_time) purchase_time FROM event_log e
    WHERE e.account_id=s.account_id AND e.user_id=s.user_id
      AND e.event_name='purchase'
      AND e.event_time >= c.cart_time
      AND e.event_time < s.signup_time + interval '7 days'
  ) p ON c.cart_time IS NOT NULL
)
SELECT COUNT(*) AS signed_up,
       COUNT(view_time) AS viewed,
       COUNT(cart_time) AS added_to_cart,
       COUNT(purchase_time) AS purchased
FROM steps;

-- Q10. Weekly signup cohorts and week-N activity retention.
WITH cohorts AS (
  SELECT account_id,user_id,
         date_trunc('week',created_at)::date AS cohort_week
  FROM app_user
), activity AS (
  SELECT DISTINCT account_id,user_id,date_trunc('week',event_time)::date AS activity_week
  FROM event_log
), cohort_size AS (
  SELECT cohort_week,COUNT(*) AS users FROM cohorts GROUP BY cohort_week
), retained AS (
  SELECT c.cohort_week,
         ((a.activity_week-c.cohort_week)/7)::int AS week_no,
         COUNT(DISTINCT (c.account_id,c.user_id)) AS retained_users
  FROM cohorts c
  JOIN activity a USING(account_id,user_id)
  WHERE a.activity_week >= c.cohort_week
  GROUP BY c.cohort_week,week_no
)
SELECT r.cohort_week,r.week_no,r.retained_users,s.users AS cohort_users,
       r.retained_users::numeric/NULLIF(s.users,0) AS retention_rate
FROM retained r JOIN cohort_size s USING(cohort_week)
ORDER BY r.cohort_week,r.week_no;

-- Q11. Consecutive active-day islands per user.
WITH active_days AS (
  SELECT DISTINCT account_id,user_id,event_time::date AS active_day FROM event_log
), numbered AS (
  SELECT active_days.*,
         ROW_NUMBER() OVER (
           PARTITION BY account_id,user_id ORDER BY active_day
         ) AS rn
  FROM active_days
), grouped AS (
  SELECT numbered.*,(active_day-rn::int) AS island_key FROM numbered
)
SELECT account_id,user_id,MIN(active_day) start_day,MAX(active_day) end_day,COUNT(*) day_count
FROM grouped GROUP BY account_id,user_id,island_key
ORDER BY account_id,user_id,start_day;
