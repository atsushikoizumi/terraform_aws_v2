import os
import datetime
import boto3

def lambda_handler(event, context):
    #
    # rds describe_db_clusters/stop_db_cluster
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

        # Status = available は処理
        if str(res['DBClusters'][i]['Status']) != 'available':
            continue

        # rds cluster を停止
        rds.stop_db_cluster(
            DBClusterIdentifier = res['DBClusters'][i]['DBClusterIdentifier']
        )


    #
    # rds describe_db_instances/stop_db_instance
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

        # DBInstanceStatus != available なら処理継続
        if str(res['DBInstances'][i]['DBInstanceStatus']) != 'available':
            continue

        # db instance を停止
        rds.stop_db_instance(
            DBInstanceIdentifier = res['DBInstances'][i]['DBInstanceIdentifier']
        )


    #
    # ec2 describe_instances/stop_instances
    #
    ec2 = boto3.client('ec2')
    res = ec2.describe_instances()

    # stop ec2 instance
    for i in range(len(res['Reservations'])):

        # タグ名でフィルター Env=tags_env, Owner=tags_owner, Name=ec2_win_name なら f=3 で処理継続
        f = 0
        for j in range(len(res['Reservations'][i]['Instances'][0]['Tags'])):
            if str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Key']) == 'Env':
                if  str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Value']) == os.environ['tags_env']:
                    f += 1
            if str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Key']) == 'Owner':
                if  str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Value']) == os.environ['tags_owner']:
                    f += 1
            if str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Key']) == 'Name':
                if  str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Value']) == os.environ['ec2_win_name']:
                    # c2 instance の状態出力
                    print(str(datetime.datetime.now()) + ' : ' + res['Reservations'][i]['Instances'][0]['Tags'][j]['Value'] + '  ' + res['Reservations'][i]['Instances'][0]['State']['Name'])
                    f += 1
                elif str(res['Reservations'][i]['Instances'][0]['Tags'][j]['Value']) == os.environ['ec2_amzn_nam']:
                    # c2 instance の状態出力
                    print(str(datetime.datetime.now()) + ' : ' + res['Reservations'][i]['Instances'][0]['Tags'][j]['Value'] + '  ' + res['Reservations'][i]['Instances'][0]['State']['Name'])
        if f < 3:
            continue

        # State = running は処理
        if str(res['Reservations'][i]['Instances'][0]['State']['Name']) != 'running':
            continue

        # ec2 instance 'ec2_win_name' を停止
        ec2.stop_instances(
            InstanceIds = [res['Reservations'][i]['Instances'][0]['InstanceId']]
        )


    #
    # redshift describe_clusters/pause_cluster
    #
    redshift = boto3.client('redshift')
    res = redshift.describe_clusters()

    # stop redshift
    for i in range(len(res['Clusters'])):

        # タグ名でフィルター Env=tags_env, Owner=tags_owner なら f=2 で処理継続
        f = 0
        for j in range(len(res['Clusters'][i]['Tags'])):
            if str(res['Clusters'][i]['Tags'][j]['Key']) == 'Env':
                if  str(res['Clusters'][i]['Tags'][j]['Value']) == os.environ['tags_env']:
                    f += 1
            if str(res['Clusters'][i]['Tags'][j]['Key']) == 'Owner':
                if  str(res['Clusters'][i]['Tags'][j]['Value']) == os.environ['tags_owner']:
                    f += 1
        if f < 2:
            continue

        # redshift Clusters の状態出力
        print(str(datetime.datetime.now()) + ' : ' + res['Clusters'][i]['ClusterIdentifier'] + '  ' + res['Clusters'][i]['ClusterStatus'])

        # ClusterStatus = available は処理
        if str(res['Clusters'][i]['ClusterStatus']) != 'available':
            continue

        # redshift を停止
        redshift.pause_cluster(
            ClusterIdentifier = res['Clusters'][i]['ClusterIdentifier']
        )
