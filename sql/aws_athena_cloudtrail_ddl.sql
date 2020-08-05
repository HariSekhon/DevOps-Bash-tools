--
--  Author: Hari Sekhon
--  Date: 2020-01-01 15:38:58 +0000 (Wed, 01 Jan 2020)
--
--  vim:ts=4:sts=4:sw=4:et:filetype=sql
--
--  https://github.com/harisekhon/devops-bash-tools
--
--  License: see accompanying Hari Sekhon LICENSE file
--
--  If you're using my code you're welcome to connect with me on LinkedIn
--  and optionally send me feedback to help improve or steer this or other code I publish
--
--  https://www.linkedin.com/in/harisekhon
--

-- replace <MY_BUCKET> and <MY_ACCOUNT_NUMBER> on last line

CREATE EXTERNAL TABLE cloudtrail_logs (
    eventversion STRING,
    useridentity STRUCT<
                   type:STRING,
                   principalid:STRING,
                   arn:STRING,
                   accountid:STRING,
                   invokedby:STRING,
                   accesskeyid:STRING,
                   userName:STRING,
    sessioncontext:STRUCT<
    attributes:STRUCT<
                   mfaauthenticated:STRING,
                   creationdate:STRING>,
    sessionissuer:STRUCT<
                   type:STRING,
                   principalId:STRING,
                   arn:STRING,
                   accountId:STRING,
                   userName:STRING>>>,
    eventtime STRING,
    eventsource STRING,
    eventname STRING,
    awsregion STRING,
    sourceipaddress STRING,
    useragent STRING,
    errorcode STRING,
    errormessage STRING,
    requestparameters STRING,
    responseelements STRING,
    additionaleventdata STRING,
    requestid STRING,
    eventid STRING,
    resources ARRAY<STRUCT<
                   ARN:STRING,
                   accountId:STRING,
                   type:STRING>>,
    eventtype STRING,
    apiversion STRING,
    readonly STRING,
    recipientaccountid STRING,
    serviceeventdetails STRING,
    sharedeventid STRING,
    vpcendpointid STRING
)
ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://<MY_BUCKET>/AWSLogs/<MY_ACCOUNT_NUMBER>/';
