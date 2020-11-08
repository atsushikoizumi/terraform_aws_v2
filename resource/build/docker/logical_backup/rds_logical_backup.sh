#!/bin/bash

# restore cluster
DB_CLUSTER_IDENTIFIER=$1
DB_CLUSTER_IDENTIFIER_RESTORE=${DB_CLUSTER_IDENTIFIER}-backup
DB_CLUSTER_IDENTIFIER_FINAL=${DB_CLUSTER_IDENTIFIER}-final
DB_INSTANCE_IDENTIFIER_RESTORE=${DB_CLUSTER_IDENTIFIER}-backup-01
DATE_TIME=`date +%Y%m%d%H%M%S`
PG_DUMP_FILE=/root/logs/${DB_CLUSTER_IDENTIFIER}_${DB_NAME}_${DATE_TIME}.dmp
LOG_FILE=/root/logs/backup_${DB_CLUSTER_IDENTIFIER}.log
if [ -f "$LOG_FILE"]; then
    touch $LOG_FILE
fi

# start
echo "=====================" 2>&1 | tee -a $LOG_FILE 2>&1
echo "===     start     ===" 2>&1 | tee -a $LOG_FILE 2>&1
echo "=====================" 2>&1 | tee -a $LOG_FILE 2>&1
if [ $? != 0 ]; then 
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when echo & tee -a LOG_FILE."
    exit
fi

# empty end
if [ "$DB_CLUSTER_IDENTIFIER" = "empty" ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] please set DB_CLUSTER_IDENTIFIER." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# describe-db-clusters 
DESCRIBE_DB_CLUSTERS=`aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER_IDENTIFIER`
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running describe-db-clusters." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
else
    ENGINE=`echo $DESCRIBE_DB_CLUSTERS | jq -r .[][].Engine`
    ENGINE_VERSION=`echo $DESCRIBE_DB_CLUSTERS | jq -r .[][].EngineVersion`
    DB_CLUSTER_PARAMETER_GROUP=`echo $DESCRIBE_DB_CLUSTERS | jq -r .[][].DBClusterParameterGroup`
fi

# describe-db-cluster-snapshots
DB_CLUSTER_SNAPSHOT_IDENTIFIERS=`aws rds describe-db-cluster-snapshots --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER" | jq -r .DBClusterSnapshots[].DBClusterSnapshotIdentifier | sort -r`
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running describe-db-cluster-snapshots." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# string to array
DB_CLUSTER_SNAPSHOT_IDENTIFIERS=($(echo "${DB_CLUSTER_SNAPSHOT_IDENTIFIERS}")) 
DB_CLUSTER_SNAPSHOT_IDENTIFIER=`echo ${DB_CLUSTER_SNAPSHOT_IDENTIFIERS[0]}`

# restore-db-cluster-from-snapshot
aws rds restore-db-cluster-from-snapshot \
    --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER_RESTORE" \
    --snapshot-identifier "$DB_CLUSTER_SNAPSHOT_IDENTIFIER" \
    --db-cluster-parameter-group-name "$DB_CLUSTER_PARAMETER_GROUP" \
    --engine "$ENGINE" \
    --engine-version "$ENGINE_VERSION" \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --port "$POSTGRESQL_PORT" \
    --vpc-security-group-ids "$VPC_SECURITY_GROUP_IDS" \
    2>&1 | tee -a $LOG_FILE
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running restore-db-cluster-from-snapshot." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# polling cluster status
status=""
while [ "available" != "$status" ]
do
    status=`aws rds describe-db-clusters --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER_RESTORE" | jq -r .DBClusters[].Status`
    date "+[%Y-%m-%d %H:%M:%S] $status" 2>&1 | tee -a $LOG_FILE 2>&1
    sleep 5s
done

# create-db-instance
aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER_RESTORE" \
    --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER_RESTORE" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine "$ENGINE" \
    --engine-version "$ENGINE_VERSION" \
    2>&1 | tee -a $LOG_FILE 2>&1

# polling instance status
status=""
while [ "available" != "$status" ]
do
    status=`aws rds describe-db-instances --db-instance-identifier "$DB_INSTANCE_IDENTIFIER_RESTORE" | jq -r .DBInstances[].DBInstanceStatus`
    date "+[%Y-%m-%d %H:%M:%S] $status" 2>&1 | tee -a $LOG_FILE 2>&1
    sleep 5s
done

# describe-db-instances
ENDPOINT=`aws rds describe-db-clusters --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER_RESTORE" | jq -r .DBClusters[].Endpoint`

# pg_dump
export PGPASSWORD=$DB_PASSWORD
pg_dump -Fc -v -w -h "${ENDPOINT}" -U ${DB_EXEC_USER} -p ${POSTGRESQL_PORT} --role=${DB_OWNER} -f "${PG_DUMP_FILE}" ${DB_NAME} 2>&1
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running pg_dump." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# aws-s3-cp
aws s3 cp $PG_DUMP_FILE s3://${S3_BUCKET}/${S3_PREFIX}/${DB_CLUSTER_IDENTIFIER}/
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running aws-s3-cp." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# delete local-dump-file
rm $PG_DUMP_FILE
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running delete local-dump-file." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# delete-db-instance
aws rds delete-db-instance \
    --db-instance-identifier "$DB_INSTANCE_IDENTIFIER_RESTORE" \
    2>&1 | tee -a $LOG_FILE 2>&1
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running delete-db-instance." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# polling instance exists
while :
do
    instancelist=`aws rds describe-db-instances | jq -r .DBInstances[].DBInstanceIdentifier`
    if [ "`echo "${instancelist}" | grep -e "$DB_INSTANCE_IDENTIFIER_RESTORE"`" ]; then
        date "+[%Y-%m-%d %H:%M:%S] $DB_INSTANCE_IDENTIFIER_RESTORE exists." 2>&1 | tee -a $LOG_FILE 2>&1
        sleep 5s
    else
        date "+[%Y-%m-%d %H:%M:%S] $DB_INSTANCE_IDENTIFIER_RESTORE deleted." 2>&1 | tee -a $LOG_FILE 2>&1
        break
    fi
done

# delete-db-cluster
aws rds delete-db-cluster \
    --db-cluster-identifier "$DB_CLUSTER_IDENTIFIER_RESTORE" \
    --no-skip-final-snapshot \
    --final-db-snapshot-identifier "$DB_CLUSTER_IDENTIFIER_FINAL" \
    2>&1 | tee -a $LOG_FILE 2>&1
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running delete-db-cluster." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# polling cluster exists
while :
do
    clusterlist=`aws rds describe-db-clusters | jq -r .DBClusters[].DBClusterIdentifier`
    if [ "`echo "${clusterlist}" | grep -e "$DB_CLUSTER_IDENTIFIER_RESTORE"`" ]; then
        date "+[%Y-%m-%d %H:%M:%S] $DB_CLUSTER_IDENTIFIER_RESTORE exists." 2>&1 | tee -a $LOG_FILE 2>&1
        sleep 5s
    else
        date "+[%Y-%m-%d %H:%M:%S] $DB_CLUSTER_IDENTIFIER_RESTORE deleted." 2>&1 | tee -a $LOG_FILE 2>&1
        break
    fi
done

# delete-db-cluster-snapshot
aws rds delete-db-cluster-snapshot \
    --db-cluster-snapshot-identifier "$DB_CLUSTER_IDENTIFIER_FINAL" \
    2>&1 | tee -a $LOG_FILE 2>&1
if [ $? != 0 ]; then
    date "+[%Y-%m-%d %H:%M:%S] [ERROR] error happned when running delete-db-cluster-snapshot." 2>&1 | tee -a $LOG_FILE 2>&1
    exit
fi

# end
date "+[%Y-%m-%d %H:%M:%S] all success end." 2>&1 | tee -a $LOG_FILE 2>&1
exit