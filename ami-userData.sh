#!/bin/bash
# 1. 패키지 업데이트 및 도커 설치
dnf update -y
dnf install -y docker

# 2. 도커 서비스 시작 및 활성화
systemctl start docker
systemctl enable docker

# 3. ec2-user를 docker 그룹에 추가 (재부팅 후 적용됨)
usermod -aG docker ec2-user

# 4. Docker Compose V2 설치 (전역 경로)
# 모든 사용자가 사용할 수 있도록 설정합니다.
DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# 5. (선택 사항) AMI 생성 전 정리
# ECR 로그인 정보나 임시 작업 내역이 AMI에 포함되지 않도록 합니다.
rm -rf /root/.docker/config.json
rm -rf /home/ec2-user/.docker/config.json

# 6. 설치 확인:/var/log/cloud-init-output.log (선택 사항 - 클라우드 초기화 로그에서 확인 가능)
docker compose version