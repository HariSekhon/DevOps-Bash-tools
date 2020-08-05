--
--  Author: Hari Sekhon
--  Date: 2020-08-05 15:08:23 +0100 (Wed, 05 Aug 2020)
--
--  vim:ts=4:sts=4:sw=4:et
--
--  https://github.com/harisekhon/bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
--
--  https://www.linkedin.com/in/harisekhon
--

-- PostgreSQL % of times indexes are used on tables by table size descending (might want to tweak to list by % descending)
--
-- If not near 99% index usage on tables > 10,000 rows, consider adding an index to match your query patterns

SELECT
  relname AS table,
  idx_scan / (seq_scan + idx_scan) * 100 AS percent_of_times_index_used,
  n_live_tup AS rows_in_table
FROM
  pg_stat_user_tables
WHERE
  seq_scan + idx_scan > 0
ORDER BY
  n_live_tup,
  percent_of_times_index_used
DESC;
