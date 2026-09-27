# 12 - 내가 만든 웹사이트를 인터넷에 올려 누구나 쓰게 하기 (AWS Web Deploy)

> 🚧 **미착수** — 디렉터리·레포 준비만 완료

VPC 로 격리된 네트워크를 직접 설계하고, EC2 에 웹 서버를 올려 **외부에서 접속 가능한**
웹 서비스를 완성한다. 보안 그룹과 IAM 최소권한을 적용하고, 장애는 로그를 근거로 추적한다.

**이 미션의 결과물은 코드가 아니라 문서 4종이다.** 애플리케이션 코드가 없다.

- 과제 원문: 로컬 `../12-aws-web-deploy.md`

## 구성

| 항목 | 값 |
|---|---|
| 리전 | 서울 `ap-northeast-2` |
| VPC | _미정_ (예: `10.0.0.0/16`) |
| Public Subnet | _미정_ (예: `10.0.1.0/24`) |
| 인스턴스 | _미정_ — 프리티어 micro 1대 (`t2.micro` 또는 `t3.micro`) |
| OS | _미정_ — Ubuntu LTS 또는 Amazon Linux |
| EBS | 8~10 GiB |
| 웹 서버 | _미정_ (Nginx 등) |
| 외부 접속 검증 방식 | **_미정_ — (A) 브라우저 `http://<퍼블릭IP>` / (B) `GET /health`** |
| 접속 정보 (URL 또는 IP) | _미배포_ |

> 과제 §4 는 검증 방식 A/B 중 어느 것을 택했는지 README 에 **명시**하도록 요구한다.

## 보안 그룹 인바운드 규칙

| 포트 | 소스 | 이유 |
|---|---|---|
| 80 (HTTP) | `0.0.0.0/0` | 누구나 접속 가능해야 하는 것이 미션의 목적 |
| 22 (SSH) | **내 IP 만** | 관리 포트를 전체 공개하면 즉시 스캔 대상이 된다 |

**금지**: `0.0.0.0/0` 에 대한 전체 포트(0-65535) 허용, `AdministratorAccess` 부여, 루트 계정 사용

## 폴더 구조

```
.
├── docs/
│   ├── architecture.(png|pdf)   # 제출물 1 — VPC/Subnet/IGW/EC2/SG + 트래픽 흐름
│   ├── troubleshooting.md       # 제출물 3 — 증상→가설→검증→조치→결과→재발방지 (최소 1건)
│   └── cleanup-checklist.md     # 제출물 4 — 리소스 정리 근거
├── screenshots/                 # 제출물 2 — 외부 접속 결과 캡처
└── README.md
```

## 트러블슈팅 기록

_(`docs/troubleshooting.md` — 미작성)_

## ⚠️ 과금 방지

리소스는 **생성 시점부터** 정리 대상으로 추적한다. 실습을 중간에 끊지 말고 한 번에
"생성 → 검증 → 캡처 → 삭제" 까지 닫는 것이 가장 안전하다.

정리 확인 필수 항목: **EC2 · EBS 볼륨 · Elastic IP · Internet Gateway · VPC**
(생성했다면 NAT Gateway · ELB/ALB · RDS 도)

## 제출물 체크리스트

- [ ] `docs/architecture.(png|pdf)` — 아키텍처 다이어그램 1장
- [ ] 외부 접속 증빙 — 방식(A/B)·접속 정보를 이 README 에 기재 + `screenshots/` 에 캡처 1장 이상
- [ ] `docs/troubleshooting.(md|pdf)` — 트러블슈팅 보고서 (최소 1건)
- [ ] `docs/cleanup-checklist.md` — 리소스 정리 체크리스트 + (선택) Billing 캡처

## 보너스

- [ ] HTTPS 적용 (무료 서브도메인 + Let's Encrypt)
- ~~Docker 컨테이너 배포~~ — **진행하지 않는다** (프로젝트 정책상 Docker 미사용)
