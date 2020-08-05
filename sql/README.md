SQL Scripts
===========

You might also be interested in `sqlcase.pl` in the [DevOps Perl tools](https://github.com/harisekhon/devops-perl-tools) repo to autocase your SQL code (I use this a lot and call it via hotkey in the `.vimrc` at the top level)

- `aws_athena_cloudtrail_ddl.sql` - [AWS Athena](https://aws.amazon.com/athena/) DDL to setup up integration to query [CloudTrail](https://aws.amazon.com/cloudtrail/) logs from Athena
- `bigquery_billing_*.sql` - [Google BigQuery](https://cloud.google.com/bigquery) billing queries
- `postgres_*.sql` - [PostgreSQL](https://www.postgresql.org/) queries for DBA investigating + performance tuning. You can quickly test these sql scripts using `postgres.sh` which boots a docker container and drops in to `psql` shell with this directory mounted at `/sql` for easy sourcing eg. `\i /sql/postgres_query_times.sql`
