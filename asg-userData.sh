#!/bin/bash
# 1. 변수 설정 (본인의 환경에 맞게 수정)
REGION="ap-south-1"  # 본인의 AWS 리전
ACCOUNT_ID="626635419731"  # 본인의 AWS 계정 ID
ECR_REPO="ian/nginx"
S3_BUCKET="static.hands-on.kr"
IMAGE_TAG="latest"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE_URI="${ECR_URL}/${ECR_REPO}:${IMAGE_TAG}"

# 2. 로그 설정 (user-data 실행 로그를 /var/log/user-data.log에 저장): ">공백>(" =>공백 주의
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# 3. 필요한 디렉토리 생성
mkdir -p /home/ec2-user/nginx/html
mkdir -p /home/ec2-user/nginx/conf.d
chown -R ec2-user:ec2-user /home/ec2-user/nginx

# 4. S3에서 최신 설정 및 자산 가져오기
aws s3 cp s3://${S3_BUCKET}/config/default.conf /home/ec2-user/nginx/conf.d/default.conf
aws s3 sync s3://${S3_BUCKET}/html/ /home/ec2-user/nginx/html/ --delete

# 5. ECR 로그인
aws ecr get-login-password --region ${REGION} | \
sudo docker login --username AWS \
--password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# 6. 최신 이미지 Pull (latest 태그 기준)
sudo docker pull ${IMAGE_URI}
sudo docker stop nginx-server || true
sudo docker rm nginx-server || true

# 7. 컨테이너 실행
sudo docker run -d --name nginx-server -p 80:80 \
  -v /home/ec2-user/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf \
  -v /home/ec2-user/nginx/html:/usr/share/nginx/html \
  ${IMAGE_URI}