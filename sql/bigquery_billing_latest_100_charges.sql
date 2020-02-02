--
--  Author: Hari Sekhon
--  Date: 2020-02-02 00:37:06 +0000 (Sun, 02 Feb 2020)
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

-- BigQuery Billing Query - latest 100 charges
SELECT
  product,
  resource_type,
  start_time,
  end_time,
  cost,
  project_id,
  project_name,
  project_labels_key,
  currency,
  currency_conversion_rate,
  usage_amount,
  usage_unit
FROM
  `myproject.mydataset.imported_billing_data`
WHERE
  Cost > 0
ORDER BY
  end_time DESC
LIMIT 100
