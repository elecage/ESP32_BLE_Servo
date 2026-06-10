# CLAUDE.md

ESP32-C3 Super Mini에서 **BLE로 서보모터를 제어**하는 펌웨어 프로젝트입니다.
빌드 시스템은 **PlatformIO**, BLE 스택은 **NimBLE-Arduino**입니다.

## 세션 시작 시 (필수)
1. `docs/HANDOFF.md`를 먼저 읽어 현재 상태와 "다음 할 일"을 파악한다.
2. 필요하면 `docs/SESSION_LOG.md`에서 과거 맥락을 확인한다.

## 세션 종료 시 (필수)
1. `docs/HANDOFF.md`의 Status / Next Actions / Decisions를 **최신 상태로 갱신**한다.
2. `docs/handoff/TEMPLATE.md` 형식으로 `docs/SESSION_LOG.md` **맨 위에 항목 추가**한다.

## 빌드 / 업로드 / 모니터
```
pio run                      # 빌드
pio run -t upload            # 보드에 업로드
pio device monitor -b 115200 # 시리얼 로그
```
개발환경 설치는 `scripts/setup_{windows.ps1,macos.sh,linux.sh}` 참조.

## 구조
- `src/main.cpp` — 펌웨어 (BLE GATT + 서보 제어). 핀/UUID 설정은 파일 상단 상수.
- `platformio.ini` — 보드/의존성 설정.
- `docs/` — 인수인계 체계(HANDOFF=현재상태, SESSION_LOG=이력).

## 규칙
- ESP32-C3는 **BLE 전용**(Bluetooth Classic 없음). BLE 코드는 NimBLE API를 쓴다.
- 핀 번호·UUID 등 하드웨어 의존 값은 `src/main.cpp` 상단 상수로만 관리한다.
- 하드웨어 검증을 못 한 변경은 HANDOFF.md에 ⬜(미검증)로 명시한다.
- 주석/문서는 한국어로 작성한다.
