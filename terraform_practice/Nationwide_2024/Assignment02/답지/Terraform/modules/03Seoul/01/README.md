# 주의 사항 #
1. source.zip 폴더 바로 아래에 위치해야 함.
================================================
예시) 
node_modules
index.js
package.json
package-lock.json
=================================================
2. local에 aws cli가 설치되있고, 권한도 존재해야 함.

# terraform 사용법 #
1. terraform apply 후 lambda/source에 있는 index.js의 5번줄의 bucket name 입력하는 곳에 자신의 S3 bucket name으로 변경 후 압축한다. (압축할 때 주의사항 참고)
2. 03Lambda.tf code의 34번 줄의 filename을 ./lambda/source.zip terraform apply 실행한다.

# 생성 후 Console #
1. 생성 후 lambda에 접속한다.
2. Add trigger 클릭
3. CloudFront 선택
4. Deploy to Lambda@Edge 클릭
5. 아래와 같이 선택 
Distribution
<생성되있는 CloudFront 선택>

Cache behavior  
</images/* 선택>

(CloudFront event) 
origin response

confirm deploy to Lambda@Edge 선택 후 deploy

# 삭제하는 법 #
terraform destory 후 S3는 수동으로 삭제 후 다시 실행하거나 직접 lambda 삭제