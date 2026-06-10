# ESP32-C3 BLE Servo Controller

ESP32-C3 Super Mini에 BLE로 접속하여 서보모터(0~180°)를 제어합니다.

🌐 **웹 제어 UI (폰/PC에서 바로 사용):** https://elecage.github.io/ESP32_BLE_Servo/
(Chrome·Edge에서 열고 **연결** 클릭 — 앱 설치 불필요)

## 빠른 시작

### 1. 개발환경 설치
| OS | 명령 |
|----|------|
| Windows | `Set-ExecutionPolicy -Scope Process Bypass -Force; .\scripts\setup_windows.ps1` |
| macOS | `chmod +x scripts/setup_macos.sh && ./scripts/setup_macos.sh` |
| Linux | `chmod +x scripts/setup_linux.sh && ./scripts/setup_linux.sh` |

각 스크립트는 프로젝트 로컬 가상환경 **`.venv`** 를 만들고 그 안에 PlatformIO Core(`pio`)를 설치합니다(시스템 Python 비오염). `--build`(맥/리눅스) 또는 `-Build`(윈도우)를 붙이면 설치 후 바로 빌드합니다.

### 2. 빌드 & 업로드
가상환경을 활성화한 뒤 사용합니다.
```
# 활성화
#   Windows :  .\.venv\Scripts\Activate.ps1
#   mac/linux: source .venv/bin/activate
pio run                       # 빌드
pio run -t upload             # 보드에 업로드
pio device monitor -b 115200  # 시리얼 로그 확인
```
활성화 없이 직접 호출도 가능: `./.venv/bin/pio ...`(mac/linux), `.\.venv\Scripts\pio.exe ...`(win).

### 3. BLE로 제어

**(권장) 웹 UI — 슬라이더/버튼으로 제어** ([web/index.html](web/index.html))

설치 없이 브라우저에서 ESP32에 직접 연결합니다(Web Bluetooth). 펌웨어 변경 불필요.
```
cd web
python -m http.server 8000
```
→ 데스크톱/안드로이드 **Chrome·Edge**에서 `http://localhost:8000` 접속 → **연결** 클릭 → 슬라이더로 제어.

> Web Bluetooth는 보안 컨텍스트에서만 동작합니다. `file://`로 직접 열면 안 되고
> `localhost` 또는 `https`(GitHub Pages 등)로 열어야 합니다. iOS는 **Bluefy** 앱 브라우저 필요.

**(대안) 범용 BLE 앱 — nRF Connect**
1. `ESP32C3-Servo` 장치에 연결
2. Service `4fafc201-...914b` 의 Command 특성(`...26a8`)에 값을 쓴다.
   - 텍스트 `"90"` → 90도
   - `"CENTER"` → 90도, `"SWEEP"` → 0→180→0 스윕
3. Status 특성(`...26a9`) Notify를 켜면 현재 각도(`ANGLE:90`)를 받는다.

## 배선

| 서보 | ESP32-C3 |
|------|----------|
| 신호(주황/노랑) | GPIO4 |
| V+ (빨강) | **별도 5V 전원** (서보 전류 큼) |
| GND (갈색/검정) | GND (전원과 공통) |

> 핀/UUID/펄스폭은 `src/main.cpp` 상단 상수에서 조정합니다.

## 문서 / 세션 인수인계
- 현재 상태: [docs/HANDOFF.md](docs/HANDOFF.md)
- 이력: [docs/SESSION_LOG.md](docs/SESSION_LOG.md)
- 프로젝트 규칙: [CLAUDE.md](CLAUDE.md)
