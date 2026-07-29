<h1 align="center">☁️ Cloud Engineering Lab</h1>

<p align="center">
  클라우드 인프라를 설계하고 운영하며 얻은 경험을 기록하는 기술 블로그형 저장소
</p>

<p align="center">
  <img src="https://img.shields.io/badge/AWS-232F3E?style=flat-square&logo=amazonaws&logoColor=white" alt="AWS" />
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white" alt="Kubernetes" />
  <img src="https://img.shields.io/badge/Terraform-844FBA?style=flat-square&logo=terraform&logoColor=white" alt="Terraform" />
  <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white" alt="GitHub Actions" />
</p>

---

## 최신 글

| 작성일 | 카테고리 | 글 |
|---|---|---|
| 2026-07-29 | Terraform / CLI | [Windows Git Bash에서 Terraform CLI 자동 완성 설정](./Terraform/cli/terraform-cli-autocomplete-windows-git-bash/) |
| 2026-05-29 | Kubernetes / EKS | [Amazon EKS 버전 업그레이드 가이드](./Kubernetes/eks/eks-upgrade-guide/) |
| 2026-05-27 | AWS / Route 53 | [Geolocation 라우팅 Failover 테스트](./AWS/route53/route53-geolocation/) |

## 카테고리

| 카테고리 | 주요 주제 | 글 |
|---|---|---:|
| [☁️ AWS](./AWS/) | 인프라 설계, 네트워크, 보안, 자동화 | 1 |
| [☸️ Kubernetes](./Kubernetes/) | EKS, OKE, 배포, 운영, 트러블슈팅 | 1 |
| [🧱 Terraform](./Terraform/) | CLI, 모듈, 상태, 백엔드, 프로바이더 | 1 |
| [🔶 OCI](./OCI/) | Compute, OKE, Network, File Storage | 0 |
| [📈 Monitoring](./Monitoring/) | OpenTelemetry, Prometheus, Grafana, ClickHouse | 0 |
| [🚀 CI/CD](./CI-CD/) | GitHub Actions, Jenkins, GitLab, Argo CD | 0 |
| [🐧 Linux](./Linux/) | 시스템, 네트워크, 운영 명령어 | 0 |
| [🩺 Troubleshooting](./Troubleshooting/) | 장애 분석, 원인 파악, 재발 방지 | 0 |

## 저장소 구조

```text
.
├── AWS/
│   └── route53/
│       └── route53-geolocation/
│           ├── README.md
│           └── terraform/
├── Kubernetes/
│   └── eks/
│       └── eks-upgrade-guide/
│           └── README.md
├── Terraform/
│   └── cli/
│       └── terraform-cli-autocomplete-windows-git-bash/
│           └── README.md
├── CI-CD/
├── Linux/
├── Monitoring/
├── OCI/
├── Troubleshooting/
└── README.md
```

각 게시글은 `카테고리/서비스/게시글/README.md` 경로에 작성합니다. 실습 코드와 설정 파일은 해당 게시글 디렉터리 안에 함께 관리하며, 디렉터리 이름은 소문자 kebab-case를 사용합니다.

## About

AWS, OCI, Kubernetes 기반 인프라의 설계·구축·운영·자동화 경험을 정리합니다. 단순한 명령어 모음보다 문제 상황, 검증 과정, 운영 시 고려사항과 재사용 가능한 코드를 함께 기록하는 것을 목표로 합니다.
