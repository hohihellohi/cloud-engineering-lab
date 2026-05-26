# Route 53 Geolocation 라우팅 Failover 테스트 정리

## 테스트 목적
Route 53에서 **Geolocation Routing** 사용 시 지역별 트래픽 분산과 장애 전환(Failover) 동작을 검증한다.
특히 `대한민국(KR)` 레코드와 `기본값(Default)` 레코드의 장애 상황에서 실제 응답이 어떻게 달라지는지 확인한다.

---

## 환경
- DNS: Amazon Route 53
- 도메인 TTL: **30초**
- 구성 대상:
  - 대한민국(KR) 레코드
  - 기본값(Default) 레코드
- 각 레코드에 Health Check 연결
- 웹 서버: Apache
- 검증 도구:
  - 실제 웹 페이지 접속
  - DNSChecker

---

## 1차 테스트
### 방식
- **Geolocation Routing만 사용**하여 테스트 진행
- 대한민국(KR) / 기본값(Default) 레코드 각각 상태 체크 연결

### 시나리오 및 결과
#### 시나리오 A: KR 서버 Apache 중지
- 기대: KR 레코드 장애 시 다른 레코드로 전환
- 결과:
  - 장애 전환 발생
  - 페이지가 도쿄(기본값) 서버로 응답됨
  - DNSChecker에서도 일본 IP 확인

#### 시나리오 B: Default(도쿄) 서버 Apache 중지
- 기대: Default 레코드 장애 시 대체 레코드로 전환
- 결과:
  - 의도한 장애 전환 미발생
  - 페이지 접속 실패 케이스 발생
  - DNSChecker 기준:
    - 한국 질의는 한국 IP 응답
    - 기본값 적용 국가 질의는 일본 IP 응답

### 1차 결론
Geolocation만 사용할 경우, **KR 레코드 장애는 Default로 폴백**되지만,
**Default 레코드 자체 장애는 자동으로 대체될 하위 경로가 없어 안정적인 Failover가 보장되지 않음**을 확인했다.

---

## 2차 테스트
### 방식
- 한국: **Geolocation Routing** 방식 유지
- 기본값: **Geolocation Routing + Failover Routing(Primary/Secondary)** 조합으로 구성

### 시나리오 및 결과
#### 시나리오: Default(Primary) 서버 Apache 중지
- 결과:
  - Health Check 비정상 감지
  - Secondary 레코드로 정상 전환
  - 페이지 및 DNS 응답 모두 Failover 동작 확인

### 2차 결론
Default를 단일 레코드로 두지 않고 **Failover(Primary/Secondary) 세트**로 구성하면,
기본값 대상 국가 트래픽에서도 기대한 장애 전환이 정상 동작한다.

---

## 원인 분석 요약
- Geolocation Routing에서 `Default`는 매칭의 최종 경로 역할을 한다.
- 따라서 Default가 단일 레코드일 때 장애가 나면 추가 대체 경로가 없다.
- 반면 Default 내부를 Failover 라우팅으로 구성하면, Primary 장애 시 Secondary로 전환할 수 있다.

### 왜 1차 테스트에서 Default는 Failover가 안 되었나?
- 1차 구성은 `Geolocation only`였기 때문에, Default 레코드는 **자체적으로 Primary/Secondary 전환 구조가 없었다.**
- KR 레코드 장애 시에는 `KR -> Default`로 내려갈 수 있어 전환이 된 것처럼 보이지만,
  Default 장애 시에는 그 아래로 내려갈 대상이 없어 자동 대체가 불가능했다.
- 즉, 문제는 Health Check 연결 유무가 아니라 **Default 레코드의 라우팅 구조(단일 레코드)**였다.

### DNSChecker에서 일본 IP가 계속 보인 이유
- Default 대상 국가는 기본적으로 Default 레코드를 참조하므로 일본 IP가 계속 관찰될 수 있다.
- 또한 DNS는 TTL(30초)과 리졸버 캐시 영향이 있어, 장애 직후에는 이전 응답이 잠시 남을 수 있다.
- 따라서 장애 전환 검증 시에는 `TTL + Health Check 판정 시간 + 리졸버 캐시`를 함께 고려해야 한다.

---

## 최종 정리
- 단순 Geolocation 구성만으로는 `Default` 장애 대응이 제한적이다.
- 운영 구성 권장안:
  - 지역별 Geolocation 정책 유지
  - `Default`는 반드시 **Failover(Primary/Secondary)** 구조로 설계
  - TTL 30초 + Health Check 임계치/간격을 서비스 요구사항에 맞게 튜닝

---

## 정책 레코드(Traffic Policy) 방식 정리

### 기존 Route53 등록 방식(개별 레코드 중심)
- 보통 Hosted Zone에서 레코드를 개별로 직접 생성한다.
- Geolocation, Failover, Weighted 같은 라우팅 정책을 레코드 단위로 따로 관리한다.
- 단순 구성에는 빠르지만, 정책이 중첩되면(예: `Geolocation + Default Failover`) 구조를 한눈에 파악하기 어려워진다.
- 여러 레코드의 이름/타입/헬스체크 연계를 수동으로 맞추다 보면 운영 중 실수 가능성이 커진다.

### 정책 레코드 방식(Traffic Policy + Policy Instance)
- 트래픽 흐름(규칙/엔드포인트)을 **정책 문서(JSON)**로 정의하고, 실제 도메인에는 Policy Instance로 연결한다.
- 즉, `geo.hohihellohi.com` 같은 실제 레코드는 "정책을 참조하는 인스턴스"가 되고, 라우팅 로직은 정책에 모아 관리한다.
- 이번 테스트의 2차 구성처럼 `KR Geolocation` + `Default 내부 Failover(Primary/Secondary)` 같은 중첩 라우팅을 명확하게 표현할 수 있다.

### 기존 방식 대비 장점
- **구조 가시성 향상**: 라우팅 의사결정(분기/폴백/장애전환)을 정책 문서 한 곳에서 확인 가능
- **변경 안정성 향상**: 레코드 여러 개를 수동 수정하는 대신 정책 버전 단위로 변경/관리 가능
- **재사용성 향상**: 유사한 트래픽 제어 요구사항을 정책 템플릿 형태로 재사용 가능
- **운영 실수 감소**: 개별 레코드 누락/불일치(이름, 타입, 헬스체크 연결) 위험을 낮춤

### 이번 실습 기준 핵심 효과
- 1차(Geolocation only)에서는 `Default` 단일 레코드 장애 시 대체 경로가 부족했다.
- 2차에서 정책 레코드 구조로 `Default Failover`를 명시함으로써:
  - KR 장애 시: `KR -> Default` 폴백
  - Default Primary 장애 시: `Default Secondary` 자동 전환
- 결과적으로 지역 기반 라우팅과 장애 전환을 동시에 만족하는 운영형 DNS 설계가 가능해졌다.

---

## 공유용 한 줄 요약
"Route 53 Geolocation에서 KR 장애는 Default로 폴백되지만, Default 단일 레코드는 장애 전환 한계가 있으므로 Default는 Failover 세트로 구성해야 안정적인 전환이 가능하다."
