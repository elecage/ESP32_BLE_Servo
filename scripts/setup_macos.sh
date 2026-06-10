#!/usr/bin/env bash
#
# ESP32-C3 BLE Servo — macOS 개발환경 설치 스크립트
# ----------------------------------------------------------------------
# 하는 일:
#   1. Python 3 / pip 확인 (없으면 Homebrew 안내)
#   2. PlatformIO Core(pio) 설치 (공식 get-platformio.py)
#   3. PATH 안내
#   4. (옵션) 프로젝트 빌드
#
# 실행:
#   chmod +x scripts/setup_macos.sh
#   ./scripts/setup_macos.sh          # 설치만
#   ./scripts/setup_macos.sh --build  # 설치 후 빌드까지
#
# ESP32-C3 Super Mini는 네이티브 USB라 별도 드라이버 불필요.
# (구형 CP2102/CH340 보드라면 해당 VCP 드라이버를 별도 설치)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> Project root: $PROJECT_ROOT"

# 1) Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "[!] python3 가 없습니다."
  echo "    Homebrew로 설치:  brew install python"
  echo "    (Homebrew가 없다면 https://brew.sh 참고)"
  exit 1
fi
echo "==> Using $(python3 --version)"

# 2) PlatformIO Core
PIO="$HOME/.platformio/penv/bin/pio"
if [ -x "$PIO" ]; then
  echo "==> PlatformIO 이미 설치됨: $PIO"
else
  echo "==> PlatformIO Core 설치 중..."
  TMP="$(mktemp -t get-platformio.XXXXXX.py)"
  curl -fsSL "https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py" -o "$TMP"
  python3 "$TMP"
  rm -f "$TMP"
  if [ ! -x "$PIO" ]; then
    echo "[!] 설치 후에도 pio 를 찾지 못했습니다. 로그를 확인하세요."
    exit 1
  fi
  echo "==> 설치 완료: $PIO"
fi

# 3) PATH 안내
SHELL_RC="$HOME/.zshrc"   # macOS 기본 zsh
PIO_BIN_DIR="$(dirname "$PIO")"
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$PIO_BIN_DIR"; then
  echo ""
  echo "PATH에 PlatformIO를 추가하려면 아래를 실행하세요:"
  echo "    echo 'export PATH=\"\$PATH:$PIO_BIN_DIR\"' >> $SHELL_RC"
  echo "    source $SHELL_RC"
fi

# 4) 옵션 빌드
if [ "${1:-}" = "--build" ]; then
  echo ""
  echo "==> 프로젝트 빌드 (의존성 다운로드 포함)..."
  ( cd "$PROJECT_ROOT" && "$PIO" run )
fi

echo ""
echo "완료. 다음 단계:"
echo "  보드 연결 후 빌드+업로드:  \"$PIO\" run -t upload"
echo "  시리얼 모니터:             \"$PIO\" device monitor -b 115200"
