#/usr/bin/bash
cd /home/ec2-user/
cat <<EOF > Dockerfile
FROM python:3.9
WORKDIR /app
RUN pip install flask
COPY . .
CMD ["python3", "src/app.py"]
EOF
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com
docker build -t wsi-ecr .
docker run -d -p 80:8080 wsi-ecr