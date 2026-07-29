# Windows VS Code에서 Terraform CLI 자동 완성 설정하기

> [홈](../../../README.md) / [Terraform](../../README.md) / [CLI](../README.md)
>
> 작성일: 2026-07-29 · 유형: 환경 설정 가이드 · 환경: Windows / VS Code / Git Bash

Windows에서 VS Code와 Terraform을 사용할 때 `terraform plan`, `terraform apply` 같은 CLI 명령을 매번 전부 입력하지 않고 `Tab` 키로 자동 완성하는 방법을 정리한다.

이 글의 구성 환경은 다음과 같다.

- Windows
- Visual Studio Code
- Git Bash
- Terraform CLI
- Terraform 실행 파일 경로 예시: `C:\terraform\terraform.exe`

> Terraform의 기본 CLI 자동 완성 설치 기능은 Bash와 Zsh를 대상으로 제공된다.  
> PowerShell에서 `terraform -install-autocomplete`를 실행하면 셸을 찾지 못했다는 오류가 발생할 수 있다.

---

## 1. PowerShell에서 발생한 오류

VS Code의 PowerShell 터미널에서 다음 명령을 실행했다.

```powershell
terraform -install-autocomplete
```

하지만 다음 오류가 발생했다.

```text
Error executing CLI: Did not find any shells to install
```

Terraform이 설치되지 않아서 발생한 오류가 아니다.

현재 사용 중인 셸이 PowerShell이기 때문에 Terraform이 자동 완성 설정을 설치할 Bash 또는 Zsh 프로필을 찾지 못한 것이다.

---

## 2. VS Code 터미널을 Git Bash로 변경

VS Code 상단 메뉴 또는 터미널 창에서 Git Bash를 선택한다.

### 기본 프로필 변경 방법

1. `Ctrl + Shift + P`를 누른다.
2. `터미널: 기본 프로필 선택`을 검색한다.
3. `Git Bash`를 선택한다.
4. 기존 PowerShell 터미널을 종료한다.
5. 새 터미널을 실행한다.

정상적으로 Git Bash가 실행되면 프롬프트가 다음과 비슷하게 표시된다.

```text
rlawh@BOOK-28QIV5SD8H MINGW64 ~/Desktop/terraform/terraform-basic
$
```

---

## 3. Bash 설정 파일 생성

Git Bash에서 `.bashrc` 파일이 존재하도록 다음 명령을 실행한다.

```bash
touch ~/.bashrc
```

`touch`는 파일이 없으면 새로 만들고, 이미 존재하면 파일 내용을 변경하지 않는다.

---

## 4. Terraform 자동 완성 설치

다음 명령을 실행한다.

```bash
terraform -install-autocomplete
```

정상적으로 처음 설치하면 Terraform이 자동 완성 설정을 `~/.bashrc`에 추가한다.

설치 후에는 Git Bash를 다시 시작하거나 다음 명령으로 설정을 즉시 다시 읽는다.

```bash
source ~/.bashrc
```

---

## 5. `already installed` 메시지가 표시되는 경우

다음과 같은 메시지가 나타날 수 있다.

```text
Error executing CLI: 1 error occurred:
        * already installed in C:\Users\rlawh\.bashrc
```

이 메시지는 자동 완성 설정이 이미 `.bashrc`에 등록되어 있다는 뜻이다.

설치를 다시 반복할 필요 없이 다음 명령만 실행한다.

```bash
source ~/.bashrc
```

또는 VS Code의 Git Bash 터미널을 완전히 종료한 뒤 새로 실행한다.

---

## 6. `.bashrc` 설정 확인

현재 `.bashrc` 내용을 확인한다.

```bash
cat ~/.bashrc
```

환경에 따라 다음과 비슷한 설정이 보일 수 있다.

```bash
complete -C C:\terraform\terraform.exe terraform.exe
```

이 줄은 `terraform -install-autocomplete`가 생성한 자동 완성 등록 설정이다.

처음부터 이 줄을 수동으로 변경하기보다는 `.bashrc`를 다시 읽은 후 자동 완성이 실제로 동작하는지 먼저 확인하는 것이 안전하다.

```bash
source ~/.bashrc
```

---

## 7. 자동 완성 테스트

다음과 같이 입력한다.

```bash
terraform pl
```

그 상태에서 `Tab` 키를 누른다.

정상적으로 동작하면 다음처럼 완성된다.

```bash
terraform plan
```

Terraform의 전체 하위 명령 후보를 확인하려면 다음처럼 입력한 뒤 `Tab`을 두 번 누른다.

```bash
terraform <Tab><Tab>
```

예상되는 명령 후보는 다음과 같다.

```text
apply
console
destroy
fmt
force-unlock
get
graph
import
init
login
logout
metadata
output
plan
providers
refresh
show
state
taint
test
untaint
validate
version
workspace
```

Terraform 버전에 따라 표시되는 명령 목록은 다를 수 있다.

---

## 8. 자동 완성 등록 상태 확인

Bash에 등록된 자동 완성 설정을 확인한다.

```bash
complete -p terraform
```

설정에 따라 실행 명령 이름이 `terraform.exe`로 등록되어 있다면 다음 명령도 확인한다.

```bash
complete -p terraform.exe
```

Terraform 실행 파일 위치는 다음 명령으로 확인한다.

```bash
command -v terraform
```

또는 다음 명령을 사용할 수 있다.

```bash
which terraform
```

예시:

```text
/c/terraform/terraform.exe
```

---

## 9. `terraform.exe`에서는 되지만 `terraform`에서는 안 되는 경우

Windows Git Bash 환경에서는 자동 완성이 `terraform.exe` 명령에만 등록되는 경우가 있다.

먼저 다음 방식으로 테스트한다.

```bash
terraform.exe pl
```

이 상태에서 `Tab`을 눌렀을 때 `terraform.exe plan`으로 완성된다면 자동 완성 기능 자체는 정상이다.

`terraform` 명령에도 동일한 자동 완성을 적용하려면 `.bashrc`에 다음 설정을 추가할 수 있다.

```bash
complete -C "$(command -v terraform)" terraform terraform.exe
```

설정을 추가한 후 다시 적용한다.

```bash
source ~/.bashrc
```

등록 상태를 확인한다.

```bash
complete -p terraform
complete -p terraform.exe
```

---

---

## 10. `terra`에서 `Tab`을 누르면 `terraform.exe`가 표시되는 이유

Git Bash에서 다음처럼 입력하고 `Tab`을 누르면:

```bash
terra<Tab>
```

다음과 같이 완성될 수 있다.

```bash
terraform.exe
```

이 현상은 오류가 아니다.

Windows에서 Terraform의 실제 실행 파일 이름이 `terraform.exe`이기 때문에 Git Bash가 PATH에 등록된 실행 파일 이름을 기준으로 명령을 완성한 것이다.

즉, 이 단계에서는 Terraform 하위 명령 자동 완성이 아니라 Git Bash의 일반 명령어 자동 완성이 동작한다.

---

## 11. Terraform 하위 명령 자동 완성 사용 방법

Terraform의 `plan`, `apply`, `validate` 같은 하위 명령 자동 완성은 Terraform 실행 명령 뒤에 공백을 입력한 상태에서 동작한다.

예를 들어 다음처럼 입력한다.

```bash
terraform.exe pl
```

그 상태에서 `Tab`을 누르면 다음처럼 완성된다.

```bash
terraform.exe plan
```

전체 하위 명령 후보를 보려면 다음처럼 입력하고 `Tab`을 두 번 누른다.

```bash
terraform.exe <Tab><Tab>
```

예상되는 후보:

```text
apply
console
destroy
fmt
force-unlock
get
graph
import
init
output
plan
providers
show
state
validate
workspace
```

Terraform 버전에 따라 후보 목록은 달라질 수 있다.

---

## 12. `.exe` 없이 `terraform`으로 사용하기

매번 `terraform.exe`가 표시되는 것이 불편하면 Git Bash에서 별칭을 설정할 수 있다.

먼저 Terraform 실행 파일의 실제 경로를 확인한다.

```bash
command -v terraform
```

예시:

```text
/c/terraform/terraform.exe
```

`.bashrc` 파일을 연다.

```bash
nano ~/.bashrc
```

다음 내용을 추가한다.

```bash
alias terraform='/c/terraform/terraform.exe'
complete -C /c/terraform/terraform.exe terraform
```

Terraform 경로가 다르면 실제 경로에 맞게 수정한다.

예를 들어 다음과 같이 출력된다면:

```text
/c/HashiCorp/Terraform/terraform.exe
```

설정도 다음처럼 작성한다.

```bash
alias terraform='/c/HashiCorp/Terraform/terraform.exe'
complete -C /c/HashiCorp/Terraform/terraform.exe terraform
```

설정을 저장한 후 다시 적용한다.

```bash
source ~/.bashrc
```

---

## 13. 별칭 및 자동 완성 설정 확인

Terraform 별칭이 정상적으로 등록되었는지 확인한다.

```bash
type terraform
```

정상 예시:

```text
terraform is aliased to '/c/terraform/terraform.exe'
```

자동 완성 등록 상태도 확인한다.

```bash
complete -p terraform
```

정상 예시:

```text
complete -C /c/terraform/terraform.exe terraform
```

이제 다음처럼 사용할 수 있다.

```bash
terraform pl<Tab>
```

결과:

```bash
terraform plan
```

---

## 14. 기존 자동 완성 줄과 충돌하는 경우

`terraform -install-autocomplete`를 실행하면 `.bashrc`에 다음과 같은 줄이 자동으로 추가될 수 있다.

```bash
complete -C C:\terraform\terraform.exe terraform.exe
```

이 설정은 `terraform.exe` 명령에만 자동 완성을 등록할 수 있다.

`terraform` 명령에도 자동 완성을 적용하려면 기존 줄을 유지한 상태에서 아래 줄을 추가할 수 있다.

```bash
alias terraform='/c/terraform/terraform.exe'
complete -C /c/terraform/terraform.exe terraform
```

또는 `terraform`과 `terraform.exe` 모두에 자동 완성을 등록할 수 있다.

```bash
complete -C /c/terraform/terraform.exe terraform terraform.exe
```

설정을 변경한 뒤에는 반드시 다시 적용한다.

```bash
source ~/.bashrc
```

등록 결과를 확인한다.

```bash
complete -p terraform
complete -p terraform.exe
```

---

## 15. 권장 `.bashrc` 최종 예시

Terraform 실행 파일이 `C:\terraform\terraform.exe`에 있는 경우 다음 구성을 사용할 수 있다.

```bash
alias terraform='/c/terraform/terraform.exe'
complete -C /c/terraform/terraform.exe terraform terraform.exe
```

적용:

```bash
source ~/.bashrc
```

테스트:

```bash
terraform pl<Tab>
```

결과:

```bash
terraform plan
```

`terra<Tab>` 입력 시 `terraform.exe`가 표시되는 것은 Windows 실행 파일 이름을 기반으로 한 일반 명령 완성이므로 정상이다. 실제 Terraform 하위 명령 자동 완성은 `terraform ` 또는 `terraform.exe ` 뒤에서 동작한다.


## 16. 자동 완성이 동작하지 않을 때 점검 순서

### 10.1 Terraform 실행 확인

```bash
terraform version
```

Terraform 버전이 정상적으로 출력되어야 한다.

### 10.2 실행 파일 경로 확인

```bash
command -v terraform
```

Terraform 실행 파일 경로가 출력되어야 한다.

### 10.3 `.bashrc` 다시 적용

```bash
source ~/.bashrc
```

### 10.4 자동 완성 등록 확인

```bash
complete -p terraform
complete -p terraform.exe
```

### 10.5 Git Bash 재실행

VS Code 터미널의 휴지통 아이콘을 눌러 기존 터미널을 종료한 뒤 Git Bash를 새로 실행한다.

### 10.6 자동 완성 재설치

기존 설정을 제거하고 다시 설치하려면 다음 명령을 사용한다.

```bash
terraform -uninstall-autocomplete
terraform -install-autocomplete
source ~/.bashrc
```

`.bashrc`를 직접 수정했다면 제거 명령이 해당 설정을 자동으로 삭제하지 못할 수 있으므로 실행 전에 파일 내용을 확인한다.

---

## 17. PowerShell을 계속 사용할 경우

Terraform의 `-install-autocomplete` 방식 대신 PowerShell의 명령 기록 기반 제안 기능을 사용할 수 있다.

```powershell
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
```

이 기능은 과거에 입력한 명령을 바탕으로 추천한다.

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Terraform 명령 구조를 기반으로 동작하는 Bash 자동 완성과는 성격이 다르다.

---

## 18. VS Code Terraform 코드 자동 완성과의 차이

Terraform 자동 완성은 크게 두 가지로 구분해야 한다.

### Terraform CLI 자동 완성

터미널에서 Terraform 명령을 완성한다.

```bash
terraform pl<Tab>
terraform plan
```

설정 방법:

```bash
terraform -install-autocomplete
```

### Terraform HCL 코드 자동 완성

VS Code 편집기에서 `.tf` 파일의 블록, 속성, 변수 참조 등을 추천한다.

권장 확장 프로그램:

```text
HashiCorp Terraform
```

예시:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
}
```

즉, 다음과 같이 역할이 구분된다.

| 기능 | 적용 위치 | 사용 도구 |
|---|---|---|
| `terraform plan` 명령 자동 완성 | 터미널 | Terraform CLI + Git Bash |
| `resource`, `variable` 문법 자동 완성 | VS Code 편집기 | HashiCorp Terraform 확장 |
| 코드 블록 생성 및 문맥 기반 제안 | VS Code 편집기 | GitHub Copilot 등의 AI 도구 |

---

## 최종 정리

Windows의 VS Code에서 Terraform CLI 자동 완성을 사용하려면 Git Bash를 사용하는 것이 가장 간단하다.

```bash
touch ~/.bashrc
terraform -install-autocomplete
source ~/.bashrc
```

이미 설치되었다는 메시지가 표시되면 재설치하지 않고 다음 명령만 실행한다.

```bash
source ~/.bashrc
```

이후 다음과 같이 입력하고 `Tab` 키를 눌러 동작을 확인한다.

```bash
terraform pl<Tab>
```

자동 완성이 정상적으로 적용되면 다음 명령으로 완성된다.

```bash
terraform plan
```

---

## 참고 문서

- HashiCorp Terraform CLI 공식 문서: Shell Tab-completion
- HashiCorp Terraform 설치 공식 튜토리얼: Enable tab completion
