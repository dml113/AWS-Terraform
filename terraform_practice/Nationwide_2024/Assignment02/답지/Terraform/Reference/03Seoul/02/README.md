# README.md

서울 2-2 Terraform Solution은 완전 자동화 입니다.  
다만 Test 채점 진행 후, Bastion Security Group 22번 port source를 my ip로 변경해줍니다.  
Config Start 활성화 후 terraform init -> terraform apply --auto-approve 진행하도록 합니다.

Terraform apply 완료 후 NameTag=wsi-test를 가진 Instance가 중복인지 아닌 지 점검합니다.

Config관련 Error가 출력이 된다면 아래 명령어를 사용하여 해결합니다.

aws configservice describe-configuration-recorders

aws configservice delete-configuration-recorder --configuration-recorder-name <recorder name 입력>

aws configservice describe-delivery-channels

aws configservice delete-delivery-channel --delivery-channel-name <existing-delivery-channel-name>
