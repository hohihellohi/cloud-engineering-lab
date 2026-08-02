# Application Load Balancer와 VPC IPAM으로 공인 IP 범위 제어하기

> [홈](../../../README.md) / [AWS](../../README.md) / [Elastic Load Balancing](../README.md)
>
> 작성일: 2025-07-17 · 유형: 실습 기록 · 원문: [Naver Blog](https://blog.naver.com/rlawhdgh4817/223937635150)

## 실습 목적

인터넷 연결 Application Load Balancer(ALB)는 AWS가 관리하는 공인 IPv4 주소를 사용한다. ALB 노드가 확장되거나 교체되면 이 주소가 달라질 수 있어, 외부 방화벽이나 허용 목록에 개별 IP를 등록하는 환경에서는 운영이 까다롭다.

ALB와 Amazon VPC IP Address Manager(IPAM)를 통합하면 ALB가 사용할 공인 IPv4 주소를 지정한 연속 CIDR 범위 안에서 할당할 수 있다. 이는 ALB에 하나의 영구 고정 IP를 부여하는 기능이 아니라, **변경 가능한 ALB IP를 예측 가능한 범위 안에서 관리하는 방식**이다.

## 참고 문서

- [AWS Blog - Simplify ALB's public IP address assignment with VPC IPAM](https://aws.amazon.com/ko/blogs/networking-and-content-delivery/simplify-albs-public-ip-address-assignment-with-vpc-ipam/)
- [Application Load Balancer와 Amazon VPC IPAM 통합 발표](https://aws.amazon.com/ko/about-aws/whats-new/2025/03/application-load-balancer-integration-vpc-ipam/)
- [Application Load Balancer IPAM IP address pools](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancers.html#ipam-pools)
- [IPAM 사용량 CloudWatch 모니터링](https://docs.aws.amazon.com/vpc/latest/ipam/cloudwatch-ipam-ip-address-usage.html)

## ALB와 IPAM 통합 개념

ALB는 클라이언트 요청을 대상 그룹의 백엔드로 전달한다. 인터넷 연결 ALB의 각 노드는 ENI와 공인 IPv4 주소를 사용하며, 기본 구성에서는 AWS가 관리하는 지역 공용 IPv4 주소 풀에서 주소가 할당된다.

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfMjgw/MDAxNzUyNzU5OTk1NTY3.28fi43UHiiA9ZOuhJmNcQ4UZfJYzejH9nRt8llIh6BEg.mcfqPqZ34eWy0JhzSC8sOkAGtu8ALqNl95wbLyx0840g.PNG/image.png" alt="ALB와 IPAM 통합 구조" width="100%">

IPAM 공용 풀을 연결하면 ALB는 해당 풀의 공인 IPv4 주소를 우선 사용한다. 사용 중인 주소는 IPAM에서 할당 상태로 확인할 수 있고, 주소가 반환되면 다시 풀에서 사용할 수 있다.

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfODcg/MDAxNzUyNzYwMjM5ODY1.0tS_udydOTINHNwy9-9IFiBn1SzS_ZqQshaKWl_oXPsg.opA2JWD6GsdsvN9Jcy2Zh7llWlbevGUTtH4H-ifeKDAg.PNG/image.png" alt="IPAM 풀을 사용하는 ALB" width="100%">

## ALB 스케일링 시 주의사항

ALB는 활성화한 각 가용 영역에 로드 밸런서 노드를 생성하고, 트래픽에 따라 노드를 확장하거나 교체한다. 노드가 추가되면 ENI와 공인 IP도 추가로 필요할 수 있다.

IPAM 풀에 할당 가능한 주소가 부족하면 Elastic Load Balancing은 가용성을 유지하기 위해 AWS 관리형 IPv4 주소를 사용한다. 이 시점부터 ALB의 주소가 지정한 CIDR 범위를 벗어날 수 있고 추가 비용도 발생할 수 있다.

따라서 운영 환경에서는 다음 항목을 함께 준비해야 한다.

- ALB 확장을 고려한 충분한 IPAM 풀 크기
- IPAM 주소 사용량에 대한 CloudWatch 경보
- 풀 고갈 전에 CIDR을 추가할 수 있는 운영 절차
- 각 ALB 서브넷에 최소 `/27` CIDR과 8개 이상의 여유 IP 확보

## 실습 환경

- 리전: `ap-northeast-2` (서울)
- 로드 밸런서: 인터넷 연결 Application Load Balancer
- 주소 관리: Amazon VPC IPAM 공용 범위
- 검증 대상: IPAM 풀 생성, ALB 연결, 할당 주소 확인

## 1. IPAM 생성

VPC 콘솔에서 IPAM을 생성한다. 인터넷 연결 ALB가 사용할 공인 IPv4 주소를 관리해야 하므로 공용 범위와 대상 리전을 확인한다.

생성 완료 후 IPAM의 공용 범위가 활성화되고 서울 리전의 리소스를 검색할 수 있는지 확인한다.

## 2. 공용 IPAM 풀 생성

생성한 IPAM의 공용 범위에서 ALB에 연결할 풀을 생성한다. 풀의 로케일은 ALB를 배치할 리전과 일치시킨다.

풀의 주소 패밀리를 `IPv4`, 범위를 `Public`, 로케일을 `ap-northeast-2`로 설정한 뒤 Amazon 제공 연속 공인 IPv4 CIDR 또는 BYOIP CIDR을 프로비저닝한다.

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfMTU2/MDAxNzUyNzYwNDQzNjYw.UpN85vFwL5pHiQ3_lFhJZcDTln1gfw3X1nIyZ1QkVgAg.w0TolNL6jQLCDUgQ8g1k8dgz2QrL9_TfMhh73SsBbyUg.PNG/image.png" alt="공용 CIDR 프로비저닝" width="100%">

### 프로비저닝 오류

실습에서는 `/28` 연속 공인 IPv4 블록을 요청했을 때 다음 오류가 발생했다.

```text
Account <ACCOUNT_ID> cannot provision an IPv4 contiguous block of size /28
in locale ap-northeast-2. Please check IPAM documentation to raise the limit.
```

이는 IPAM 생성 실패가 아니라 계정에 적용된 연속 공인 IPv4 CIDR 쿼터 문제다. Service Quotas와 [IPAM 쿼터 문서](https://docs.aws.amazon.com/vpc/latest/ipam/quotas-ipam.html)에서 현재 허용 크기를 확인하고, 더 큰 블록이 필요하면 AWS Support를 통해 상향을 요청해야 한다. 기본값과 허용 범위는 변경될 수 있으므로 실습 시점의 콘솔 값을 기준으로 확인한다.

## 3. ALB에 IPAM 풀 연결

ALB 생성 화면의 네트워크 매핑에서 인터넷 연결 스킴과 IPv4 주소 유형을 선택한 뒤, 공용 IPv4 주소에 사용할 IPAM 풀을 지정한다.

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfOTYg/MDAxNzUyNzYwNTEyMjQ0.EL_R5C8RGRmgdM3AWDhtYvthZoTVwNQPhsI-2WQnrrYg.IKCbstKpib_t125NaV8HAPlmFgernRbR2MUItsUaMjkg.PNG/image.png" alt="ALB IPAM 풀 선택" width="100%">

보안 그룹과 대상 그룹을 구성하고 ALB를 생성한다. 대상 그룹은 실습용 백엔드에 맞게 구성했으며, ALB 노드와 공인 IP 개수는 대상 그룹 수가 아니라 활성화한 가용 영역과 ALB의 확장 상태에 따라 결정된다.

기존 ALB에도 EC2 콘솔의 `Load Balancers > Network mapping > Edit IP pools`에서 IPAM 풀을 연결할 수 있다.

## 4. IP 할당 확인

ALB 생성 후 Elastic IP 주소와 IPAM 대시보드에서 할당 상태를 확인한다. ALB가 사용하는 주소에는 서비스 관리 속성이 표시되며 사용자가 직접 수정하거나 해제할 수 없다.

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfMjMz/MDAxNzUyNzYwNTUwNjkz.9ZtKlOG5uIk3Np6_4IMEspMEE94__XIxOLyv2uJMQ6Ag.o9Z3GhnyQY07sj9Y_R1uAxDYmvcey3eYCHXm2DX9WHUg.PNG/image.png" alt="ALB 관리형 공인 IP 확인" width="100%">

<img src="https://postfiles.pstatic.net/MjAyNTA3MTdfMTIg/MDAxNzUyNzYwNTgwMTc5.hun5KlXnfPyAw9ckfC2VIMOhn6o4U-Me7qim9PzYWkEg.wJwvIPQ0Lx-Ag-amdohJxhRXaHJqQXVzMHvRgcFf__Ag.PNG/image.png" alt="IPAM 주소 할당 상태" width="100%">

ALB의 DNS 이름은 일반적으로 활성화된 가용 영역마다 하나의 ALB 노드 IP로 해석된다. 확장이나 교체 과정에서 개별 주소는 달라질 수 있지만, IPAM 풀에 여유가 있다면 지정한 CIDR 범위 안에서 주소가 할당된다.

## 5. EIP에도 IPAM 풀 사용

IPAM의 연속 공인 IPv4 범위는 ALB뿐 아니라 Elastic IP 주소 할당에도 사용할 수 있다. 외부 방화벽 정책에 연속된 주소 범위를 등록해야 하는 환경에서 관리 부담을 줄일 수 있다.

## 최종 정리

- ALB와 IPAM을 통합하면 ALB 공인 IPv4 주소를 예측 가능한 CIDR 범위에서 관리할 수 있다.
- 개별 ALB IP가 영구적으로 고정되는 것은 아니며, 노드 확장과 교체에 따라 주소는 변경될 수 있다.
- IPAM 풀이 고갈되면 AWS 관리형 공인 IPv4 주소로 대체되므로 사용량 경보와 확장 절차가 필요하다.
- ALB 노드와 IP 개수는 대상 그룹 수가 아니라 활성화된 가용 영역과 ALB 확장 상태에 따라 결정된다.
- 개별 고정 IP가 필요하다면 AWS Global Accelerator 또는 ALB를 대상으로 사용하는 Network Load Balancer 구성도 검토할 수 있다.

## 공유용 한 줄 요약

> ALB와 VPC IPAM을 통합하면 개별 IP를 고정하는 대신, ALB가 사용할 공인 IPv4 주소를 예측 가능한 CIDR 범위 안에서 관리할 수 있다.
