# README.md


dmin_codecommit_credential.txt 해당 이름을 가진 파일은 git 자격증명에 대한 정보를 저장한 파일입니다.

- First !
  
buildspec.yml,start.sh 파일을 열어서 <ACCOUNT_ID> 부분을 본인 AccountID로 변경합니다.

아래 명령어를 그대로 사용하여 codecommit 폴더에 있는 내용을들을 전부 CodeCommit에 Push하도록합니다.
```
git init
git remote add origin <CODECOMMIT_HTTPS_URL>
git branch -m main
git checkout main
git add -A
git commit -m "Commit Busan 2-3"
git push -u origin main
<자격증명 입력>
```
