# README.md

- First !
  
아래 Notion URL로 접근하여 그대로 따라합니다.

https://sunset-squash-626.notion.site/2024-2-22938532d6184c088497b89d08447cd5

- Second !
  
Reference/05Gwangju/02/files/kube/values.yaml 해당 파일을 편집 모드로 전향합니다.

image.repository 부분의 <ACCOUNT_ID> 부분을 본인 ACCOUNT ID로 수정 합니다.

Reference/05Gwangju/02/files/buildspec.yml 해당 파일을 편집 모드로 전향합니다.

<ACCOUNT_ID>,<ARGOCD_URL> 부분을 본인 ACCOUNT ID와 ARGOCD URL로 수정합니다.

ARGOCD_URL은 kubectl get svc argocd-server -n argocd 해당 명령어를 통해 알 수 있습니다.

- Third !
  
Reference/05Gwangju/02/files 의 내용들을 전부 gwangju-application-repo이라는 CodeCommit에 업로드 합니다.

(Notion상세히 설명 되어있음)
