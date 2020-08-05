--
--  Author: Hari Sekhon
--  Date: 2020-08-05 16:16:21 +0100 (Wed, 05 Aug 2020)
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
  ROUND((total_time / 1000)::numeric, 4) AS total_secs,
  -- newer versions of PostgreSQL have mean_time field, don't need to calculate
  --ROUND((total_time / 1000 / calls)::numeric, 4) AS average_secs,
  ROUND(mean_time::numeric / 1000, 4) AS average_secs,
  ROUND(min_time::numeric / 1000, 4) AS min_secs,
  ROUND(max_time::numeric / 1000, 4) AS max_secs,
  ROUND(stddev_time::numeric / 1000, 4) AS stddev_secs,
  query
FROM
  pg_stat_statements
ORDER BY
  average_secs DESC,
  calls DESC,
  rows DESC
LIMIT 100;
