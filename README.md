# ESP32-C3 BLE Servo Controller

ESP32-C3 Super Mini에 BLE로 접속하여 서보모터(0~180°)를 제어합니다.

## 빠른 시작

### 1. 개발환경 설치
| OS | 명령 |
|----|------|
| Windows | `Set-ExecutionPolicy -Scope Process Bypass -Force; .\scripts\setup_windows.ps1` |
| macOS | `chmod +x scripts/setup_macos.sh && ./scripts/setup_macos.sh` |
| Linux | `chmod +x scripts/setup_linux.sh && ./scripts/setup_linux.sh` |

각 스크립트는 PlatformIO Core(`pio`)를 설치합니다. `--build`(맥/리눅스) 또는 `-Build`(윈도우)를 붙이면 설치 후 바로 빌드합니다.

### 2. 빌드 & 업로드
```
pio run                       # 빌드
pio run -t upload             # 보드에 업로드
pio device monitor -b 115200  # 시리얼 로그 확인
```

### 3. BLE로 제어
스마트폰 **nRF Connect**(또는 BLE 앱)로:
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
