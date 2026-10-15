#!/bin/bash
# 미션 12 · 2단계 프라이빗 웹 EC2(lab-web) User data — Amazon Linux 2023
# 첫 부팅 때 cloud-init 이 root 로 한 번 실행한다. 실행 기록은 /var/log/cloud-init-output.log
# 공인 IP 가 없으므로 dnf 저장소와 Docker Hub 에는 NAT Gateway 로 나간다.
# → 이 인스턴스를 만들기 전에 NAT Gateway 와 private-rt(0.0.0.0/0 → NAT)가 있어야 한다.
set -euxo pipefail

dnf install -y docker
systemctl enable --now docker

# IMDSv2 는 호스트에서 읽는다 (컨테이너 안에서 읽으려면 hop limit 을 늘려야 해서 피한다)
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
md() { curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$1"; }
INSTANCE_ID=$(md instance-id)
AZ=$(md placement/availability-zone)
PRIVATE_IP=$(md local-ipv4)

# 페이지와 nginx 설정은 호스트 폴더에 두고 컨테이너에 읽기 전용으로 붙인다
mkdir -p /opt/web/html /opt/web/conf.d

cat > /opt/web/html/index.html <<EOF
<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><title>m12 · lab-web</title></head>
<body style="font-family:system-ui,sans-serif;margin:3rem;line-height:1.6">
<h1>Hello Cloud</h1>
<p>응답한 서버: <b>lab-web</b> — 프라이빗 서브넷 · Docker 컨테이너 (ALB 경유)</p>
<ul>
  <li>instance-id: ${INSTANCE_ID}</li>
  <li>availability-zone: ${AZ}</li>
  <li>private-ip: ${PRIVATE_IP}</li>
</ul>
</body></html>
EOF

cat > /opt/web/conf.d/default.conf <<'EOF'
server {
    listen 80;

    location = /health {
        default_type text/plain;
        return 200 "OK";
    }

    location / {
        root  /usr/share/nginx/html;
        index index.html;
    }
}
EOF

# 호스트 80 → 컨테이너 80. 재부팅해도 컨테이너가 다시 뜨도록 restart 정책을 준다
docker run -d --name web --restart unless-stopped \
  -p 80:80 \
  -v /opt/web/html:/usr/share/nginx/html:ro \
  -v /opt/web/conf.d:/etc/nginx/conf.d:ro \
  nginx:1.27-alpine
