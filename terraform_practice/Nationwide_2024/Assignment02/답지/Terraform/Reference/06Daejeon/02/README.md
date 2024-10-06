# README.md

대전 2-2 Terraform Solution은 완전 자동화 입니다.

Config Start 활성화 후 terraform init -> terraform apply --auto-approve 진행하도록 합니다.

Terraform apply 완료 후 NameTag=wsi-app-ec2를 가진 Instance가 중복인지 아닌 지 점검합니다.

Config관련 Error가 출력이 된다면 아래 명령어를 사용하여 해결합니다.

aws configservice describe-delivery-channels

aws configservice delete-delivery-channel --delivery-channel-name <existing_delivery_channel_name>

aws configservice describe-configuration-recorders

aws configservice delete-configuration-recorder --configuration-recorder-name <recorders name>
