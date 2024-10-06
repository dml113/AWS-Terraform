import boto3
import requests
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    instance_id = os.environ['INSTANCE_ID']  # 환경 변수에서 instance_id 가져오기
    security_group_ids = get_security_group_ids(ec2, instance_id)
    my_ip = get_external_ip()

    for sg_id in security_group_ids:
        # 필요한 인그레스 규칙
        required_ingress = [
            {'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'IpRanges': [{'CidrIp': f'{my_ip}/32'}]},
            {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'UserIdGroupPairs': [{'GroupId': sg_id}]},
            {'IpProtocol': 'tcp', 'FromPort': 3306, 'ToPort': 3306, 'UserIdGroupPairs': [{'GroupId': sg_id}]}
        ]

        # 필요한 이그레스 규칙
        required_egress = [
            {'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'IpRanges': [{'CidrIp': '0.0.0.0/0'}]},
            {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'IpRanges': [{'CidrIp': '0.0.0.0/0'}]},
            {'IpProtocol': 'tcp', 'FromPort': 443, 'ToPort': 443, 'IpRanges': [{'CidrIp': '0.0.0.0/0'}]}
        ]

        # 현재 보안 그룹 규칙 가져오기
        response = ec2.describe_security_groups(GroupIds=[sg_id])
        security_group = response['SecurityGroups'][0]

        current_ingress = security_group.get('IpPermissions', [])
        current_egress = security_group.get('IpPermissionsEgress', [])

        # 현재와 필요한 규칙 비교 및 수정
        update_security_group(ec2, sg_id, current_ingress, required_ingress, 'ingress')
        update_security_group(ec2, sg_id, current_egress, required_egress, 'egress')

def get_security_group_ids(ec2, instance_id):
    response = ec2.describe_instances(InstanceIds=[instance_id])
    security_groups = response['Reservations'][0]['Instances'][0]['SecurityGroups']
    return [sg['GroupId'] for sg in security_groups]

def get_external_ip():
    ip = requests.get('https://api.ipify.org').text
    return ip

def update_security_group(ec2, sg_id, current_rules, required_rules, rule_type):
    # 필요한 규칙을 직렬화 가능한 형태로 변환합니다.
    required_rules_serialized = [serialize_rule(rule) for rule in required_rules]
    
    # 제거할 규칙과 추가할 규칙 식별
    to_revoke = [rule for rule in current_rules if serialize_rule(rule) not in required_rules_serialized]
    to_add = [rule for rule in required_rules if serialize_rule(rule) not in [serialize_rule(cur_rule) for cur_rule in current_rules]]

    # 규칙 제거
    if to_revoke:
        if rule_type == 'ingress':
            ec2.revoke_security_group_ingress(GroupId=sg_id, IpPermissions=to_revoke)
        else:
            ec2.revoke_security_group_egress(GroupId=sg_id, IpPermissions=to_revoke)

    # 규칙 추가
    if to_add:
        if rule_type == 'ingress':
            ec2.authorize_security_group_ingress(GroupId=sg_id, IpPermissions=to_add)
        else:
            ec2.authorize_security_group_egress(GroupId=sg_id, IpPermissions=to_add)

def serialize_rule(rule):
    # 규칙을 직렬화 가능한 형태로 변환합니다.
    return tuple(sorted(rule.items()))
