--
--  Author: Hari Sekhon
--  Date: 2020-08-05 18:34:44 +0100 (Wed, 05 Aug 2020)
--
--  vim:ts=2:sts=2:sw=2:et:filetype=sql
--
--  https://github.com/harisekhon/bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/harisekhon
--

-- List PostgreSQL stale connections that have been idle > 10 mins
--
-- Tested on PostgreSQL 12.3

SELECT
  rank() over (partition by client_addr order by backend_start ASC) as rank,
  pid,
  backend_start,
  query_start,
  state_change,
  datname,
  user,
  client_addr
FROM
  pg_stat_activity
WHERE
  -- don't kill yourself
  pid <> pg_backend_pid()
  --  AND
  -- don't kill your admin tools
  --application_name !~ '(?:psql)|(?:pgAdmin.+)'
  --  AND
  --usename not in ('postgres')
    AND
  query in ('')
    AND
  (
    (current_timestamp - query_start) > interval '10 minutes'
      OR
    (query_start IS NULL AND (current_timestamp - backend_start) > interval '10 minutes')
  )
;
