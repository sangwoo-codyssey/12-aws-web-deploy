# 리소스 정리 체크리스트

> **상태: 정리 전** — 2026-10-15 기준으로 모든 리소스를 유지하고 있다. 과제 완료를 선언할 때 아래 순서대로 한 번에 지우고,
> 각 행의 "확인" 칸에 CLI 조회 결과(빈 목록)를 근거로 채운다.

- 리전: 서울 `ap-northeast-2`. 실습 리소스 대부분에 태그 `Project=m12` 를 붙였지만 빠진 것도 있다(`lab-vpc` · `lab-public` · HTTPS 리스너).
  그래서 아래 확인 명령은 태그로 거르지 않는다.
- 실습 전 기준선(2026-10-15 15:13): 인스턴스·NAT·ALB·EIP·공인 IPv4 **0개**, VPC 는 기본 VPC(172.31.0.0/16) 하나뿐.
  **정리가 끝나면 이 기준선으로 돌아와야 한다.**
- 과제 필수 확인 항목: **EC2 · EBS · Elastic IP · Internet Gateway · VPC** (표에 ★ 표시)

## 과금 요인 — 무엇이 돈을 쓰고 있나

| 리소스 | 과금 방식 | 이 실습의 해당 리소스 |
|---|---|---|
| NAT Gateway | 켜져 있는 **시간** + 처리한 데이터 GB | `lab-nat` |
| ALB | 켜져 있는 **시간** + 사용량 단위(LCU) | `lab-alb` |
| 공인 IPv4 주소 | 주소 하나당 **시간** (EC2 자동 할당 · EIP · ALB 노드 모두) | 52.79.161.105 · EIP 54.116.21.105 · ALB 노드 2개 |
| EC2 | 실행 중인 **시간** | `lab-public` · `lab-web` (t3.micro) |
| EBS | 할당된 **용량 × 시간** — 인스턴스를 *중지*해도 계속 나간다 | 8 GiB gp3 × 2 |
| Elastic IP | 위 공인 IPv4 요금. 연결을 끊고 해제하지 않은 EIP 도 계속 과금된다 | `lab-nat-eip` |

과금되지 않는 것: VPC · 서브넷 · 라우트 테이블 · IGW · 보안 그룹 · 대상 그룹 · 키 페어 · IAM · ACM 공인 인증서.
요금은 없지만 다음에 만들 때 이름이 겹치거나, 남은 권한이 보안 위험이 되므로 함께 지운다.
Route 53 호스팅 영역 `crypbot.app` 은 실습 전부터 있던 것이라 유지한다. 실습에서 만든 레코드 2개만 지운다.

## 정리 순서

**의존하는 쪽을 먼저 지운다.** 다른 리소스가 쓰고 있는 네트워크 리소스(서브넷 · SG · IGW · EIP · 인증서)는 삭제가 거부된다.
ALB 는 서브넷·SG·인증서를 쓰고, NAT 는 EIP·서브넷을 쓰고, EC2 는 SG·서브넷·역할을 쓴다.
의존 관계가 없는 것끼리는 순서를 바꿔도 된다. 예를 들어 NAT 는 EC2 와 무관하므로 3 보다 먼저 지워도 된다.

| # | 리소스 | ID | 방법 · 주의 | 확인 (정리 후 기입) |
|---|---|---|---|---|
| 1 | ALB `lab-alb` (리스너 2개 포함) | `app/lab-alb/8495c14cab355e58` | 삭제하면 리스너도 함께 지워진다. ALB 노드의 공인 IPv4 2개(이름 없는 13.124.133.236 · 3.35.215.246)도 자동으로 반납된다 — **직접 해제하지 않는다** | ☐ |
| 2 | 대상 그룹 `lab-tg` | `targetgroup/lab-tg/87685f2e23264c9d` | ALB 삭제 뒤에 지운다(리스너가 쓰는 동안은 거부) | ☐ |
| 3 ★ | EC2 `lab-web` · `lab-public` 종료 | `i-0a22f04b520445fda` · `i-092b6a3c00bbee442` | `lab-public` 의 자동 할당 공인 IPv4 도 종료와 함께 반납된다 | ☐ |
| 4 ★ | EBS 루트 볼륨 2개 | `vol-06342f7434f63e59e` · `vol-05362c3f459827666` | 둘 다 `DeleteOnTermination: True`(2026-10-15 20:51 조회) → 3 과 함께 지워진다. **남은 볼륨 0개를 직접 확인한다** | ☐ |
| 5 | NAT Gateway `lab-nat` | `nat-0bacd1650fd3d5a8e` | 상태가 `deleted` 가 될 때까지 기다린다(몇 분). 그 전에는 6 의 EIP 가 아직 연결돼 있다 | ☐ |
| 6 ★ | Elastic IP `lab-nat-eip` 해제(Release) | `eipalloc-0bc9c4236c4d43f0c` (54.116.21.105) | "연결 해제"만 하면 안 되고 **해제(Release)** 까지 해야 과금이 멈춘다 | ☐ |
| 7 | Route 53 레코드 2개 | `m12.crypbot.app` A(별칭) · `_c8f0….m12.crypbot.app` CNAME(ACM 검증) | 호스팅 영역과 기존 레코드(NS · SOA · TXT)는 그대로 둔다 | ☐ |
| 8 | ACM 인증서 `m12.crypbot.app` | `certificate/7c93bb00-6a43-427f-9dcd-034a767de279` | ALB 가 지워져 `InUseBy` 가 비어야 삭제된다 | ☐ |
| 9 | 보안 그룹 4개 | `web-sg` `sg-054d68a42e3f95617` → `alb-sg` `sg-09e31ec0b5b33122d` · `bastion-sg` `sg-06e5ee790ae80d191` · `public-sg` `sg-0f013d721a4a2ba91` | **web-sg 를 먼저** 지운다 — web-sg 의 규칙이 alb-sg · bastion-sg 를 출처로 참조하고 있어서, 참조되는 쪽을 먼저 지우면 거부된다. VPC 의 `default` SG 는 VPC 와 함께 지워진다 | ☐ |
| 10 ★ | Internet Gateway `lab-igw` | `igw-057393382633edab5` | VPC 에서 **분리(Detach)** 한 뒤 삭제 | ☐ |
| 11 | 서브넷 3개 | `lab-public-a` `subnet-020964110159af855` · `lab-public-c` `subnet-0e42ac94b0e779454` · `lab-private-a` `subnet-045ac56d84dfde9e2` | 남은 네트워크 인터페이스(ENI)가 있으면 거부된다 → 1~5 가 끝났는지 먼저 본다 | ☐ |
| 12 | 라우트 테이블 2개 | `public-rt` `rtb-07dcfd170b02c44a8` · `private-rt` `rtb-041f8ab97e02c6bb2` | 기본(main) 라우트 테이블은 VPC 와 함께 지워진다 | ☐ |
| 13 ★ | VPC `lab-vpc` | `vpc-04b89b36a6e5f95b3` | 기본 라우트 테이블 · 기본 NACL · default SG 가 함께 지워진다 | ☐ |
| 14 | 키 페어 `lab-key` | — | AWS 쪽 키 페어 삭제 + 내 PC 의 `.pem` 파일 삭제 | ☐ |
| 15 | IAM 역할 `lab-ec2-ssm` (인스턴스 프로파일 포함) | — | **루트로** 삭제(lab-user 에는 IAM 역할을 지울 권한이 없다) | ☐ |
| 16 | IAM 사용자 `lab-user` · 정책 `lab-m12` | — | 과금은 없다. 남겨 둘지는 정리 때 결정한다(남기면 콘솔 비밀번호 비활성화) | ☐ |
| 17 | CLI 로그인 세션 | 프로파일 `m12` | `aws logout --profile m12`. Access Key 는 처음부터 만들지 않았다(`aws login` 사용) | ☐ |
| 18 | Billing | — | 다음 날 루트로 Billing · Cost Explorer 에서 서울 리전 EC2 · ELB · VPC(NAT · 공인 IPv4) 요금이 더 늘지 않는지 확인 | ☐ |

## 확인 명령 — 정리 후 실행

모든 명령에 `--profile m12 --region ap-northeast-2` 를 붙인다. 읽기 명령만 쓴다.
태그 필터(`Project=m12`)는 쓰지 않았다. 태그를 빠뜨린 리소스가 남아 있어도 빈 목록이 나와 통과로 보이기 때문이다.

```bash
# 3·4 EC2 · EBS — 실행/중지 상태 인스턴스 0개, 볼륨 0개
#     (정리 전 서울 리전 볼륨은 두 인스턴스의 루트 볼륨 2개뿐이었다 — 2026-10-15 20:51 조회)
aws ec2 describe-instances --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[].InstanceId'                        # 기대: []
aws ec2 describe-volumes --query 'Volumes[].VolumeId'                   # 기대: []

# 1·2 ALB · 대상 그룹
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'   # 기대: []
aws elbv2 describe-target-groups --query 'TargetGroups[].TargetGroupName'      # 기대: []

# 5·6 NAT · EIP · 공인 IPv4 — 삭제된 NAT 는 한동안 'deleted' 로 보이므로 상태로 거른다
aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available,deleting \
  --query 'NatGateways[].NatGatewayId'                                   # 기대: []
aws ec2 describe-addresses --query 'Addresses[].PublicIp'                # 기대: [] (ALB 노드 IP 포함)

# 7·8 Route 53 · ACM
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --query 'ResourceRecordSets[].[Type,Name]'                             # 기대: NS · SOA · TXT 3개만
aws acm list-certificates --query 'CertificateSummaryList[].DomainName'  # 기대: []

# 9~13 네트워크 — 기본 VPC 만 남아야 한다
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,IsDefault]'      # 기대: 172.31.0.0/16 · True 1개
aws ec2 describe-internet-gateways \
  --query 'InternetGateways[].[InternetGatewayId,Attachments[0].VpcId]'  # 기대: 기본 VPC 에 붙은 IGW 1개만
aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-04b89b36a6e5f95b3 \
  --query 'SecurityGroups[].GroupName'                                   # 기대: []
aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=vpc-04b89b36a6e5f95b3 \
  --query 'NetworkInterfaces[].NetworkInterfaceId'                       # 기대: []

# 14 키 페어 · (참고) 남은 SSM 세션
aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName'                  # 기대: lab-key 없음
aws ssm describe-sessions --state Active --query 'Sessions[].SessionId'  # 기대: []
```

- IAM 역할 · 사용자 · 정책(15 · 16)은 lab-user 로 조회할 수 없다(인스턴스 프로파일 목록만 볼 수 있다). 루트로 콘솔에서 확인하고 캡처한다.
- 결과 원본과 캡처를 이 문서 "확인" 칸과 [`screenshots/`](../screenshots/)에 남긴다.
