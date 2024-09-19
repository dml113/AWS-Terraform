1. git 자격 증명은 테라폼 실행 경로에 저장됩니다.

2. bation에 대한 키 페어도 테라폼 실행 경로에 저장됩니다. 

3. 간혹 테라폼을 실행 시키고 나면 역할에 정책이 빠져있어 오류가 뜰때가 있습니다 이 경우에 테라폼을 한 번더 실행 시키면 정상적으로 정책이 들어가므로 참고 바랍니다.

#밑에 부터는 테라폼으로 구축 후 설정합니다.

4. src/app.py, appspec.yml, buildspec.yml, Dockerfile, install.sh, start.sh, stop.sh -> app.py 파일은 src/ 디렉토리 안에 위치해야합니다.

5. codecommit에 푸시하기 전에 buildspec.yml을 열어서 구축하려는 계정의 accountid를 복사하여 buildspec에 ecr 푸시 부분에 넣거나 그냥 ecr 푸시 명령어를 순차적으로 붙여넣으면 됩니다.
    -> codecommit에 있는 start.sh 파일을 열어서 ecr 로그인 명령어 부분의 "003150130236"을 자신의 accountid로 변경합니다. 

5. codecommit에 파일들을 git 명령어를 통해 따로 업로드 해야 합니다 밑에 명령어를 참고합니다.

파일들이 있는 경로에서 cmd를 열어 git init -> git branch -m main -> git remote add origin (HTTPS) 예시) git remote add origin https://git-codecommit.ap-northeast-2.amazonaws.com/v1/repos/wsi-repo
-> git add . -> git commit -m "f" -> git push -u origin main를 하면 자격 증명 입력 칸이 나오면 admin_codecommit_credential.txt 파일 내용을 순차적으로 입력하면 codecommit에 업로드 됩니다.