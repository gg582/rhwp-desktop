# rhwp-desktop (hwp-editor)

`rhwp` 프로젝트의 **WASM 코어 + rhwp-studio UI**를 기반으로 만든 **데스크톱(standalone) 프로그램**입니다.

웹 데모([`edwardkim.github.io/rhwp`](https://edwardkim.github.io/rhwp/))와 동일한 UI/기능을 목표로 하며, Electron으로 패키징합니다.

## rhwp 프로젝트
- 리포: https://github.com/edwardkim/rhwp
- 데모: https://edwardkim.github.io/rhwp

## 기반 프로젝트 / 버전

- **rhwp WASM 코어**: `core/pkg/` (`@rhwp/core` — upstream에서 빌드 후 동기화)
- **rhwp-studio UI**: `ui/` (upstream `rhwp-studio` 동기화 + `ui/desktop-overlay/` 데스크톱 패치)

## 라이선스

Copyright (c) 2026 Runable.app

이 프로젝트는 `rhwp`와 동일하게 **MIT License**를 따릅니다(상속).  
라이선스 전문은 저장소 루트의 `LICENSE` 파일을 참고하세요.  
WASM 산출물은 `core/pkg/` (`@rhwp/core`)에 포함되며, 해당 패키지의 라이선스/고지를 참조하세요.

## 폴더 구조

- `ui/`: rhwp-studio (Vite) + `ui/desktop-overlay/` (Electron 전용 패치)
- `core/pkg/`: rhwp WASM (`@rhwp/core` npm 패키지 형태)
- `desktop/`: Electron 앱(파일 열기/저장 IPC 포함)
- `run-desktop.sh`: 빌드 후 Electron 실행 스크립트
- `scripts/build-rhwp-wasm-and-sync.sh`: upstream rhwp에서 WASM + UI 동기화

## upstream rhwp 동기화 (WASM + UI)

최신 rhwp를 가져와 WASM을 빌드하고, `rhwp-studio` UI를 동기화한 뒤 데스크톱 overlay를 적용합니다.

```bash
cd hwp-editor
./scripts/build-rhwp-wasm-and-sync.sh
```

기본 동작:

1. `https://github.com/edwardkim/rhwp` `main` 브랜치를 `.cache/rhwp-upstream`에 clone/update
2. WASM 빌드 (Docker 사용 가능 시 Docker, otherwise `wasm-pack`)
3. `core/pkg/`에 `@rhwp/core` 산출물 복사
4. `rhwp-studio` → `ui/` 동기화
5. `ui/desktop-overlay/` 적용 (Electron 파일 다이얼로그, about 다이얼로그 등)
6. `ui/`에서 `npm install` (`@rhwp/core` → `file:../core/pkg`)

로컬 rhwp 클론을 쓰려면:

```bash
RHWP_DIR=/path/to/rhwp ./scripts/build-rhwp-wasm-and-sync.sh
```

rhwp는 테스트 PDF를 Git LFS로 관리합니다. 동기화 스크립트는 WASM/UI 빌드에 LFS 파일이 필요 없으므로
기본적으로 LFS 다운로드를 건너뜁니다 (`GIT_LFS_SKIP_SMUDGE=1`). upstream LFS 예산 오류가 나면
`.cache/rhwp-upstream`을 삭제한 뒤 스크립트를 다시 실행하세요.

GitHub Actions 릴리스 빌드도 동일 스크립트를 실행합니다.

데스크톱 전용 UI 변경은 `ui/src/`가 아니라 `ui/desktop-overlay/`를 수정하세요.

## 실행

```bash
cd hwp-editor
./run-desktop.sh
```

(최신 upstream을 쓰려면 먼저 `./scripts/build-rhwp-wasm-and-sync.sh` 실행)

## 빌드 (전체 + AppImage)

한 번에 UI/데스크톱을 빌드하고 Linux AppImage까지 생성합니다.

```bash
cd hwp-editor
./build.sh
```

결과 AppImage는 `desktop/release/` 아래에 생성됩니다.

## Linux AppImage 빌드

```bash
cd hwp-editor/desktop
npm run dist:linux
```

결과물은 `desktop/release/` 아래에 생성됩니다.

## Linux distro 패키징 및 시스템 설치

프로젝트 루트에서 다음 스크립트들을 사용할 수 있습니다. Electron 런타임과 모든
애플리케이션 자산이 함께 묶여 있어 대상 시스템에 Node.js나 빌드 도구가 필요하지
않습니다. 기본적으로 호스트 아키텍처(x64/arm64)로 빌드되며, `ARCH=x64` 또는
`ARCH=arm64`로 대상 아키텍처를 지정할 수 있습니다.

### Static build wrapper

```bash
./scripts/build-static.sh              # 호스트 아키텍처
ARCH=arm64 ./scripts/build-static.sh   # arm64로 크로스 빌드
```

`dist-static/rhwp-desktop-<version>-linux-<arch>/` 디렉터리와
`dist-static/rhwp-desktop-<version>-linux-<arch>.tar.gz`를 만듭니다.

### 시스템 전체 설치

```bash
sudo ./install.sh
# 또는
sudo ARCH=arm64 ./install.sh
```

`/opt/rhwp-desktop`에 설치하고 `/usr/bin/rhwp-desktop` 심볼릭 링크, 데스크톱
엔트리, 아이콘을 등록합니다.

### Debian/Ubuntu (.deb)

```bash
# fpm 설치 필요
sudo apt-get install -y ruby ruby-dev build-essential rpm
sudo gem install fpm

./scripts/build-deb.sh
# ARCH=arm64 ./scripts/build-deb.sh
```

`dist-static/rhwp-desktop-<version>-linux-<arch>.deb`가 생성됩니다.

### Fedora/RHEL (.rpm)

```bash
# fpm 설치 필요
sudo dnf install -y ruby ruby-devel gcc make rpm-build
sudo gem install fpm

./scripts/build-rpm.sh
# ARCH=arm64 ./scripts/build-rpm.sh
```

`dist-static/rhwp-desktop-<version>-linux-<arch>.rpm`가 생성됩니다.

### Slackware (SlackBuild)

```bash
./scripts/prepare-slackbuild.sh
```

`slackbuild/dist/rhwp-desktop-slackbuild-<version>-<slackware-arch>.tar.gz`를
만듭니다(x86_64, aarch64). 이 tarball은 SlackBuild 스크립트, `.info`, `.desktop`,
아이콘을 포함하며 GitHub Release에 함께 업로드됩니다. Slackware 사용자는 자신의
아키텍처에 맞는 tarball을 풀고 `./rhwp-desktop.SlackBuild`를 실행하면 됩니다.

### GitHub Actions 자동 배포

`.github/workflows/release-desktop.yml`이 태그 푸시 시 자동으로 x64/arm64
AppImage, static tarball, `.deb`, `.rpm`, SlackBuild tarball을 빌드하여 GitHub
Release에 첨부합니다.
