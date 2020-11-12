import os
import datetime
import boto3

def lambda_handler(event, context):
    #
    # rds describe_db_clusters/start_db_cluster
    #
    rds = boto3.client('rds')
    res = rds.describe_db_clusters()

    # stop rds cluster
    for i in range(len(res['DBClusters'])):

        # タグ名でフィルター Env=tags_env, Owner=tags_owner なら f=2 で処理継続
        f = 0
        for j in range(len(res['DBClusters'][i]['TagList'])):
            if str(res['DBClusters'][i]['TagList'][j]['Key']) == 'Env':
                if  str(res['DBClusters'][i]['TagList'][j]['Value']) == os.environ['tags_env']:
                    f += 1
            if str(res['DBClusters'][i]['TagList'][j]['Key']) == 'Owner':
                if  str(res['DBClusters'][i]['TagList'][j]['Value']) == os.environ['tags_owner']:
                    f += 1
        if f < 2:
            continue

        # DBCluster の状態出力
        print(str(datetime.datetime.now()) + ' : ' + res['DBClusters'][i]['DBClusterIdentifier'] + '  ' + res['DBClusters'][i]['Status'])

        # Status = stopped は処理
        if str(res['DBClusters'][i]['Status']) != 'stopped':
            continue

        # DBCluster start
        rds.start_db_cluster(
            DBClusterIdentifier = res['DBClusters'][i]['DBClusterIdentifier']
        )

    #
    # rds describe_db_instances/start_db_instance
    #
    res = rds.describe_db_instances()

    # stop db instance
    for i in range(len(res['DBInstances'])):

        # タグ名でフィルター Env=tags_env, Owner=tags_owner なら f=2 で処理継続
        f = 0
        for j in range(len(res['DBInstances'][i]['TagList'])):
            if str(res['DBInstances'][i]['TagList'][j]['Key']) == 'Env':
                if  str(res['DBInstances'][i]['TagList'][j]['Value']) == os.environ['tags_env']:
                    f += 1
            if str(res['DBInstances'][i]['TagList'][j]['Key']) == 'Owner':
                if  str(res['DBInstances'][i]['TagList'][j]['Value']) == os.environ['tags_owner']:
                    f += 1
        if f < 2:
            continue

        # aurora 以外なら処理継続
        if 'aurora' in str(res['DBInstances'][i]['Engine']):
            continue

        # DBInstances の状態出力
        print(str(datetime.datetime.now()) + ' : ' + res['DBInstances'][i]['DBInstanceIdentifier'] + '  ' + res['DBInstances'][i]['DBInstanceStatus'])

        # DBInstanceStatus != stopped なら処理継続
        if str(res['DBInstances'][i]['DBInstanceStatus']) != 'stopped':
            continue

        # start db instance
        rds.start_db_instance(
            DBInstanceIdentifier = res['DBInstances'][i]['DBInstanceIdentifier']
        )
