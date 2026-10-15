#!/bin/bash
# 미션 12 · 1단계 퍼블릭 EC2(lab-public) User data — Amazon Linux 2023
# 첫 부팅 때 cloud-init 이 root 로 한 번 실행한다. 실행 기록은 /var/log/cloud-init-output.log
# 퍼블릭 서브넷이라 IGW 경로로 dnf 저장소에 바로 나간다.
set -euxo pipefail

dnf install -y nginx

# IMDSv2: 토큰을 먼저 받아야 메타데이터를 읽을 수 있다 (AL2023 기본값이 v2 필수)
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
md() { curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
INSTANCE_ID=$(md instance-id)
AZ=$(md placement/availability-zone)
PRIVATE_IP=$(md local-ipv4)

# 화면만 보고도 어느 인스턴스가 응답했는지 알 수 있게 한다
cat > /usr/share/nginx/html/index.html <<EOF
<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><title>m12 · lab-public</title></head>
<body style="font-family:system-ui,sans-serif;margin:3rem;line-height:1.6">
<h1>Hello Cloud</h1>
<p>응답한 서버: <b>lab-public</b> — 퍼블릭 서브넷 · Nginx 직접 설치</p>
<ul>
  <li>instance-id: ${INSTANCE_ID}</li>
  <li>availability-zone: ${AZ}</li>
  <li>private-ip: ${PRIVATE_IP}</li>
</ul>
</body></html>
EOF

# AL2023 nginx.conf 의 기본 server 블록은 /etc/nginx/default.d/*.conf 를 불러온다
cat > /etc/nginx/default.d/health.conf <<'EOF'
location = /health {
    default_type text/plain;
    return 200 "OK";
}
EOF

nginx -t
systemctl enable --now nginx
