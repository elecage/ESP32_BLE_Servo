#!/usr/bin/env bash
#
# ESP32-C3 BLE Servo — macOS 개발환경 설치 스크립트
# ----------------------------------------------------------------------
# 하는 일:
#   1. Python 3 확인 (없으면 Homebrew 안내)
#   2. 프로젝트 로컬 가상환경 .venv 생성 (시스템 Python 오염 방지)
#   3. .venv 안에 PlatformIO Core(pio) 를 pip로 설치
#   4. (옵션) 프로젝트 빌드
#
# 실행:
#   chmod +x scripts/setup_macos.sh
#   ./scripts/setup_macos.sh          # 설치만
#   ./scripts/setup_macos.sh --build  # 설치 후 빌드까지
#
# 설치 후 사용:
#   ./.venv/bin/pio run        # 직접 호출, 또는
#   source .venv/bin/activate  # 활성화 후 'pio run'
#
# ESP32-C3 Super Mini는 네이티브 USB라 별도 드라이버 불필요.
# (구형 CP2102/CH340 보드라면 해당 VCP 드라이버를 별도 설치)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$PROJECT_ROOT/.venv"
echo "==> Project root: $PROJECT_ROOT"

# 1) Python 3
if ! command -v python3 >/dev/null 2>&1; then
  echo "[!] python3 가 없습니다."
  echo "    Homebrew로 설치:  brew install python"
  echo "    (Homebrew가 없다면 https://brew.sh 참고)"
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
    echo "[!] .venv 생성 실패. 'python3 -m venv' 동작을 확인하세요."
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

# 4) 옵션 빌드
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
