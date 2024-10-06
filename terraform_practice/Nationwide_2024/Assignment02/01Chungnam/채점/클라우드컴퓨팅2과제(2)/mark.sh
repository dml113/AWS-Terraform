#!/bin/bash
echo "------------------------------- 2024 전국기능경기대회 2과제 CICD 부분 채점기준표 -------------------------------"
echo "------------------------------- 1-1 -------------------------------"
aws codecommit get-repository --repository-name wsc2024-cci --query "repositoryMetadata.repositoryName"
echo "-------------------------------------------------------------------"
echo "------------------------------- 1-2 -------------------------------"

list_files() {
    local folder_path=$1
    aws codecommit get-folder --repository-name wsc2024-cci --commit-specifier master --folder-path "$folder_path" --region us-west-1 --query 'subFolders[*].absolutePath' --output text | tr '\t' '\n' | while read subfolder; do
        list_files "$subfolder"
    done
    aws codecommit get-folder --repository-name wsc2024-cci --commit-specifier master --folder-path "$folder_path" --region us-west-1 --query 'files[*].absolutePath' --output text
}

file_list=$(list_files "/")
echo "File list: $file_list"
found_directives=false

for file_path in $file_list; do
    echo "Processing file: $file_path"
    file_content=$(aws codecommit get-file --repository-name wsc2024-cci --file-path "$file_path" --query 'fileContent' --output text | base64 --decode)
    if echo "$file_content" | grep -E "^\s*(FROM|COPY|CMD)"; then
        if [ "$found_directives" = false ]; then
            echo "FROM python:3.12-slim"
            echo "COPY . ."
            echo "CMD [\"python3\", \"app.py\"]"
            found_directives=true
        fi
    fi
done

if ! $found_directives; then
    aws codepipeline start-pipeline-execution --name wsc2024-pipeline --region us-west-1
    echo "출력된 결과에 Dockerfile에 대한 구문이 없으므로 위에 명령어를 실행 하였습니다."
else
    echo "오답처리를 합니다."
fi

echo "-------------------------------------------------------------------"
echo "------------------------------- 2-1 -------------------------------"
aws codebuild batch-get-projects --names wsc2024-cbd --query "projects[*].name"
echo "-------------------------------------------------------------------"
echo "------------------------------- 3-1 -------------------------------"
aws deploy get-application --application-name wsc2024-cdy --query "application.applicationName"
echo "-------------------------------------------------------------------"
echo "------------------------------- 4-1 -------------------------------"
aws codepipeline get-pipeline --name wsc2024-pipeline --query "pipeline.name"
echo "-------------------------------------------------------------------"
echo "------------------------------- 4-2 -------------------------------"
echo "수동 채점 필요함. *채점기준표 확인*"
echo "-------------------------------------------------------------------"
echo "------------------------------- 5-1 -------------------------------"
elb_dns=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName" --output text)
if [[ -z "$elb_dns" ]]; then
    echo "Error: ELB DNS name not found."
else
    curl "$elb_dns/healthcheck"
fi