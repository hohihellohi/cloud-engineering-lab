# Amazon EKS 버전 업그레이드 가이드 (실무용)

> [홈](../../../README.md) / [Kubernetes](../../README.md) / [Amazon EKS](../README.md)
>
> 기준일: 2026-05-29 · 유형: 운영 가이드

이 문서는 EKS 클러스터를 안전하게 업그레이드하는 절차와, 각 단계를 왜 그렇게 수행해야 하는지 설명합니다.

---

## 1. 핵심 원칙

### 1.1 다운그레이드는 불가
- EKS는 클러스터 버전 업그레이드 후 이전 버전으로 되돌릴 수 없습니다.
- 따라서 운영 클러스터 업그레이드는 "배포"처럼 계획/검증/롤백전략(Blue/Green)을 갖고 진행해야 합니다.

### 1.2 Minor 버전은 한 단계씩만
- 예: `1.33 -> 1.35` 직접 업그레이드 불가
- 올바른 경로: `1.33 -> 1.34 -> 1.35`
- 이유: Kubernetes/EKS 버전 스큐 정책 및 제어면 안정성 보장

### 1.3 Control Plane과 Data Plane 책임 분리
- Control Plane 업그레이드 실행/관리: AWS
- Node/Fargate Pod/Add-on 정렬: 사용자 책임
- 즉, Control Plane만 올리고 끝내면 버전 불일치로 장애 가능성 증가

---

## 2. 권장 업그레이드 순서

1. 사전 점검 (Insights, API deprecation(예전 버전인 워크로드 매니페스트가 구버전에 의존하면 동작이 깨질 수 있다.), IP 여유, add-on 호환성(Kubernetes API와 kubelet/kube-proxy 동작에 직접 의존))
2. Control Plane 업그레이드
3. Node Group 업그레이드 (Managed/Self-managed/Fargate 반영)
4. 핵심 Add-on 업그레이드 (`vpc-cni`, `coredns`, `kube-proxy`)
5. 운영 도구 업그레이드 (`kubectl`, autoscaler 등)
6. 사후 검증

왜 이 순서인가?
- API 서버(Control Plane)가 기준점입니다.
- 기준점을 먼저 올린 다음, 그 API를 사용하는 노드/애드온/도구를 순차 정렬해야 호환 리스크를 낮출 수 있습니다.

---

## 3. 사전 점검 (Pre-check)

## 3.1 Upgrade Insights 이해 및 확인
- `Upgrade Insights`는 EKS가 클러스터를 스캔해서, 다음 Kubernetes 버전 업그레이드에 영향을 줄 수 있는 이슈를 사전에 알려주는 진단 기능입니다.
- `Cluster Insights`의 하위 유형이며, 업그레이드 실패 가능성을 사전에 줄이는 목적입니다.

무엇을 점검하나?
- 제거 예정(Deprecated/Removed) Kubernetes API 사용 여부
- `kubelet`/`kube-proxy` 버전 스큐(호환 범위) 문제
- EKS add-on 버전 호환성 문제
- 클러스터 헬스 이슈(업그레이드 저해 가능 상태)

상태 해석
- `PASSING`: 현재 점검 기준 문제 없음
- `WARNING`: 주로 미래 버전(N+2 이상)에서 영향 가능
- `ERROR`: 다음 버전(N+1) 업그레이드 영향 가능성이 커서 조치 권장
- `UNKNOWN`: 현재 정보로 판단 불가

운영 포인트
- 기본적으로 약 24시간 주기로 갱신되며, 수동 새로고침도 가능합니다.
- Deprecated API 사용 탐지는 최근 30일 사용 이력을 기준으로 반영될 수 있어, 수정 후 즉시 상태가 바뀌지 않을 수 있습니다.
- 비용 관점에서도 사전 점검으로 장애/재작업 가능성을 낮춰 인건비와 변경 실패 비용을 줄일 수 있습니다.

CLI 확인 예시
```bash
aws eks start-insights-refresh --region <region> --cluster-name <cluster>
aws eks describe-insights-refresh --cluster-name <cluster>
aws eks list-insights --region <region> --cluster-name <cluster>
aws eks describe-insight --region <region> --cluster-name <cluster> --id <insight-id>
```

## 3.2 현재/지원 버전 확인
```bash
aws eks describe-cluster --name <cluster> --region <region> --query "cluster.version"
aws eks describe-cluster-versions
```

왜 필요한가?
- 지원 종료 임박 버전이면 강제 일정 대응이 필요합니다.
- 업그레이드 목표 버전을 정확히 정하지 않으면, 중간 단계 누락으로 실패합니다.
- 지원 정책을 넘기면 Extended Support 과금 구간에 오래 머물 수 있어 클러스터 시간당 비용이 증가할 수 있습니다.

## 3.3 서브넷 가용 IP 확인
```bash
CLUSTER=<cluster>
aws ec2 describe-subnets --subnet-ids \
  $(aws eks describe-cluster --name ${CLUSTER} --query 'cluster.resourcesVpcConfig.subnetIds' --output text) \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,AvailableIpAddressCount]' \
  --output table
```

왜 필요한가?
- Control Plane 업그레이드 시 EKS가 새 ENI를 생성하며 최대 5개 가용 IP가 필요합니다.
- IP 부족은 업그레이드 실패의 대표 원인입니다.
- 업그레이드 윈도우 중 실패/재시도로 작업 시간이 길어지면 운영 인건비와 변경 윈도우 기회비용이 증가합니다.

## 3.4 노드 버전 확인
```bash
kubectl version
kubectl get nodes -o wide
```

왜 필요한가?
- kubelet 버전이 과도하게 낮으면 업그레이드 후 호환 문제가 생길 수 있습니다.
- 실무적으로 Control Plane과 노드 minor를 맞추는 것이 가장 안전합니다.
- 버전 불일치 상태를 오래 유지하면 장애 분석/운영 복잡도가 올라가고, 그만큼 운영 비용이 누적됩니다.

## 3.5 Add-on 호환 버전 확인
```bash
aws eks list-addons --cluster-name <cluster> --region <region>
aws eks describe-addon-versions --addon-name <addon> --kubernetes-version <target_minor>
```

왜 필요한가?
- EKS는 Control Plane 업그레이드 시 add-on을 자동 업그레이드하지 않습니다.
- 특히 `vpc-cni`, `coredns`, `kube-proxy`, CSI, ALB Controller는 버전 불일치 시 장애로 이어질 수 있습니다.
- 네트워크/DNS/스토리지 계층 장애는 영향 범위가 넓어, 복구 시간 증가에 따른 비즈니스 비용이 큽니다.

---

## 4. 실행 단계 (Runbook)

## 4.1 (권장) 스테이징 리허설
- 운영과 동일한 버전/애드온/워크로드 조건에서 사전 리허설
- 이유: deprecated API, webhook, PDB 문제를 운영에서 처음 만나지 않기 위함

## 4.2 Control Plane 업그레이드
```bash
aws eks update-cluster-version \
  --name <cluster> \
  --kubernetes-version <next_minor> \
  --region <region>
```

상태 확인
```bash
aws eks describe-update --name <cluster> --region <region> --update-id <update-id>
```

왜 먼저 하나?
- API 기준점(제어면)을 먼저 확정해야, 나머지 컴포넌트를 그 기준에 맞게 정렬할 수 있습니다.
- 순서가 뒤집히면 재작업 가능성이 높아지고, 결과적으로 변경 시간과 인건비가 증가합니다.

## 4.3 Managed Node Group 업그레이드
```bash
aws eks update-nodegroup-version \
  --cluster-name <cluster> \
  --nodegroup-name <nodegroup> \
  --region <region>
```

왜 다음이 노드인가?
- 워크로드가 실제 실행되는 데이터 플레인입니다.
- Control Plane과 노드 버전 불일치는 스케줄링/네트워크/애드온 동작 리스크를 높입니다.
- 노드 정렬이 늦어지면 장애 가능 시간대가 길어지고, 장애 대응 비용과 고객 영향 비용이 커집니다.

PDB 관련 주의(PDB - 이 앱 Pod를 최소 몇 개는 살아있게 유지해라”를 정하는 Kubernetes 정책, 노드 교체 중에 Pod가 한꺼번에 내려가 서비스가 끊기는 걸 방지)
- 노드 교체 시 EKS는 Pod drain을 시도합니다.
- PDB 제약으로 drain이 막히면 업데이트가 실패할 수 있습니다.
- 최우선은 PDB/워크로드 정책 수정이고, 강제 업데이트(force)는 최후수단입니다.

## 4.4 Fargate 사용 시
- 기존 Fargate Pod는 자동으로 새 kubelet로 전환되지 않습니다.
- 재배포/재시작으로 새 Pod를 띄워 반영해야 합니다.

## 4.5 Add-on 업그레이드
```bash
aws eks update-addon \
  --cluster-name <cluster> \
  --addon-name <addon> \
  --addon-version <version> \
  --resolve-conflicts PRESERVE
```

왜 `PRESERVE`를 고려하나?
- 기존 커스텀 설정(값)을 보존하기 위함입니다.
- `OVERWRITE`는 EKS 기본값으로 덮어쓸 수 있어 운영 설정이 사라질 수 있습니다.
- 커스텀 설정 유실 시 장애 복구/재설정에 추가 시간이 들며, 이는 즉시 운영 비용으로 연결됩니다.

중요
- EKS Add-on은 자동 업그레이드되지 않습니다.
- EKS Add-on은 일반적으로 한 번에 한 minor 단계씩 업그레이드합니다.

## 4.6 운영 도구 버전 정렬
- `kubectl`은 클러스터 Control Plane과 minor 차이 제한(일반적으로 ±1) 내 유지
- Cluster Autoscaler 등은 대상 Kubernetes minor에 맞는 릴리스로 업그레이드

왜 필요한가?
- 도구 버전 불일치는 운영 명령 실패, 의도치 않은 동작, 스케일링 오작동으로 이어질 수 있습니다.
- 자동화 파이프라인 실패율이 올라가면 배포 지연과 재시도 비용(인력/시간)이 반복적으로 발생합니다.

---

## 5. 사후 검증 (Post-check)

```bash
kubectl get nodes
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp
aws eks list-insights --region <region> --cluster-name <cluster>
```

검증 포인트
- 모든 노드 Ready
- 핵심 네임스페이스(`kube-system`, ingress/controller, observability) 에러 없음
- 재시작 급증/CrashLoopBackOff 없음
- Upgrade Insights가 ERROR/WARNING 없이 PASSING 또는 관리 가능한 상태

---

## 6. 실패/리스크 대응 전략

## 6.1 가장 흔한 실패 원인
- 서브넷 IP 부족
- deprecated API 미정리
- add-on 버전 불호환
- PDB 때문에 node drain 실패

## 6.2 대응 원칙
- 한 단계씩 진행하고, 단계마다 헬스체크 후 다음 단계로 이동
- 대규모 점프(여러 minor)는 Blue/Green 전환 검토
- 운영 반영 전 스테이징 리허설 필수

## 6.3 비용 관점 체크포인트
- Extended Support 비용: 지원 종료 일정 전에 업그레이드해 불필요한 연장지원 과금을 줄입니다.
- 장애 비용: 사전 점검(Insights, Add-on 호환성, PDB 점검)으로 장애 확률을 낮춰 복구 비용을 줄입니다.
- 운영 인건비: 단계별 자동화 스크립트/런북을 유지해 반복 작업 시간을 단축합니다.
- 기회비용: 업그레이드 실패 재시도를 줄여 변경 윈도우와 릴리스 일정을 보호합니다.

---

## 7. 최소 실행 커맨드 세트

```bash
# 0) 현재 상태
aws eks describe-cluster --name <cluster> --region <region> --query "cluster.version"
kubectl get nodes

# 1) Insights
aws eks start-insights-refresh --region <region> --cluster-name <cluster>
aws eks list-insights --region <region> --cluster-name <cluster>

# 2) Control Plane
aws eks update-cluster-version --name <cluster> --kubernetes-version <next_minor> --region <region>

# 3) Node Group (각 노드그룹 반복)
aws eks update-nodegroup-version --cluster-name <cluster> --nodegroup-name <ng> --region <region>

# 4) Add-ons
aws eks list-addons --cluster-name <cluster> --region <region>
aws eks update-addon --cluster-name <cluster> --addon-name vpc-cni --addon-version <ver> --resolve-conflicts PRESERVE
aws eks update-addon --cluster-name <cluster> --addon-name coredns --addon-version <ver> --resolve-conflicts PRESERVE
aws eks update-addon --cluster-name <cluster> --addon-name kube-proxy --addon-version <ver> --resolve-conflicts PRESERVE
```

---

## 참고 문서 (AWS 공식)
- https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html
- https://docs.aws.amazon.com/eks/latest/best-practices/cluster-upgrades.html
- https://docs.aws.amazon.com/eks/latest/userguide/update-managed-node-group.html
- https://docs.aws.amazon.com/eks/latest/userguide/updating-an-add-on.html
- https://docs.aws.amazon.com/eks/latest/userguide/addon-compat.html
- https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
- https://docs.aws.amazon.com/eks/latest/userguide/cluster-insights.html
- https://docs.aws.amazon.com/eks/latest/userguide/view-cluster-insights.html
- https://docs.aws.amazon.com/eks/latest/APIReference/API_UpdateNodegroupVersion.html
