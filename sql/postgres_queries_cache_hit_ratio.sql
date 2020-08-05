--
--  Author: Hari Sekhon
--  Date: 2020-08-05 16:22:42 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL query times from pg_stat_statement

-- postgresql.conf needs before start:
-- shared_preload_libraries = 'pg_stat_statements'
--
CREATE extension pg_stat_statements;

SELECT
  calls,
  rows,
  shared_blks_hit,
  shared_blks_read,
  -- using greatest() to avoid divide by zero error, by ensuring we divide by at least 1
    shared_blks_hit /
    GREATEST((shared_blks_hit + shared_blks_read), 1)::float AS shared_blks_hit_ratio,
    -- casting divisor to float to avoid getting integer maths returning zeros instead of fractional ratios
  local_blks_hit,
  local_blks_read,
    local_blks_hit /
    GREATEST((local_blks_hit + local_blks_read), 1)::float AS local_blks_hit_ratio,
  query
FROM
  pg_stat_statements
--ORDER BY rows DESC
ORDER BY
  shared_blks_hit_ratio DESC,
  local_blks_hit_ratio DESC,
  rows DESC
LIMIT 100;
