--
--  Author: Hari Sekhon
--  Date: 2020-08-05 17:54:19 +0100 (Wed, 05 Aug 2020)
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

-- PostgreSQL tables by size, excluding catalog and information schema
--
-- Tested on PostgreSQL 12.3

SELECT
	nspname || '.' || relname AS relation,
  pg_size_pretty(pg_total_relation_size(C.oid)) AS total_size
FROM
 	pg_class C
LEFT JOIN
	pg_namespace N ON (N.oid = C.relnamespace)
WHERE
	nspname NOT IN ('pg_catalog', 'information_schema')
  	AND
	C.relkind <> 'i'
   	AND
	nspname !~ '^pg_toast'
ORDER BY
	pg_total_relation_size(C.oid) DESC;
