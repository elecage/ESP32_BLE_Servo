#!/usr/bin/env bash
#
# ESP32-C3 BLE Servo — Linux 개발환경 설치 스크립트
# ----------------------------------------------------------------------
# 하는 일:
#   1. Python 3 / venv 확인 (없으면 apt/dnf 안내)
#   2. 프로젝트 로컬 가상환경 .venv 생성 (시스템 Python 오염 방지)
#   3. .venv 안에 PlatformIO Core(pio) 를 pip로 설치
#   4. 시리얼 포트 권한(dialout) + udev 규칙 안내
#   5. (옵션) 프로젝트 빌드
#
# 실행:
#   chmod +x scripts/setup_linux.sh
#   ./scripts/setup_linux.sh          # 설치만
#   ./scripts/setup_linux.sh --build  # 설치 후 빌드까지
#
# 설치 후 사용:
#   ./.venv/bin/pio run        # 직접 호출, 또는
#   source .venv/bin/activate  # 활성화 후 'pio run'
#
# ESP32-C3 Super Mini는 네이티브 USB라 별도 드라이버 불필요.
# 단, 시리얼 포트 접근 권한 설정이 필요할 수 있다(아래 안내 참고).

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$PROJECT_ROOT/.venv"
echo "==> Project root: $PROJECT_ROOT"

# 1) Python 3 + venv
if ! command -v python3 >/dev/null 2>&1; then
  echo "[!] python3 가 없습니다. 배포판에 맞게 설치하세요:"
  echo "    Debian/Ubuntu:  sudo apt update && sudo apt install -y python3 python3-venv python3-pip"
  echo "    Fedora:         sudo dnf install -y python3 python3-pip"
  echo "    Arch:           sudo pacman -S python"
  exit 1
fi
if ! python3 -c "import venv" >/dev/null 2>&1; then
  echo "[!] python3-venv 모듈이 없습니다. 설치 후 다시 실행하세요:"
  echo "    Debian/Ubuntu:  sudo apt install -y python3-venv"
  exit 1
fi
echo "==> Using $(python3 --version)"

# 2) 가상환경(.venv) 생성
VENV_PY="$VENV_DIR/bin/python"
if [ -x "$VENV_PY" ]; then
  echo "==> 가상환경 이미 존재: $VENV_DIR"
else
  echo "==> 가상환경 생성: $VENV_DIR"
  python3 -m venv "$VENV_DIR"
  if [ ! -x "$VENV_PY" ]; then
    echo "[!] .venv 생성 실패. python3-venv 설치 여부를 확인하세요."
    exit 1
  fi
fi

# 3) .venv 안에 PlatformIO 설치
echo "==> pip / PlatformIO 설치(업데이트) 중..."
"$VENV_PY" -m pip install --upgrade pip >/dev/null
"$VENV_PY" -m pip install --upgrade platformio
PIO="$VENV_DIR/bin/pio"
if [ ! -x "$PIO" ]; then
  echo "[!] 설치 후에도 pio 를 찾지 못했습니다. 로그를 확인하세요."
  exit 1
fi
echo "==> 설치 완료: $PIO ($("$PIO" --version))"

# 4) 시리얼 포트 권한 안내
echo ""
echo "[시리얼 권한] 업로드 시 /dev/ttyACM0 접근 권한이 필요합니다."
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx "dialout"; then
  echo "  현재 사용자를 dialout 그룹에 추가하세요(이후 재로그인 필요):"
  echo "    sudo usermod -aG dialout $USER"
fi
echo "  PlatformIO udev 규칙(권장):"
echo "    curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules \\"
echo "      | sudo tee /etc/udev/rules.d/99-platformio-udev.rules"
echo "    sudo udevadm control --reload-rules && sudo udevadm trigger"

# 5) 옵션 빌드
if [ "${1:-}" = "--build" ]; then
  echo ""
  echo "==> 프로젝트 빌드 (의존성 다운로드 포함)..."
  ( cd "$PROJECT_ROOT" && "$PIO" run )
fi

echo ""
echo "완료. 다음 단계:"
echo "  (활성화) source .venv/bin/activate   이후 'pio ...' 로 사용"
echo "  또는 직접 호출:"
echo "    ./.venv/bin/pio run -t upload             # 빌드+업로드"
echo "    ./.venv/bin/pio device monitor -b 115200  # 시리얼 모니터"
