# 세션 인수인계 (Handoff) — 현재 상태

> 이 문서는 **항상 최신 상태**를 담는 단일 진실 공급원(single source of truth)입니다.
> 새 세션은 이 문서를 가장 먼저 읽고, 세션을 마칠 때 이 문서를 갱신하세요.
> 시간순 이력은 [SESSION_LOG.md](SESSION_LOG.md)에 누적합니다.

- **최종 갱신:** 2026-06-10
- **갱신자:** Claude (초기 구축 세션)
- **프로젝트 한 줄 요약:** ESP32-C3 Super Mini에서 BLE로 서보모터(0~180°)를 제어하는 펌웨어 + 크로스플랫폼 빌드환경.

---

## 1. 지금 어디까지 됐나 (Status)

| 항목 | 상태 |
|------|------|
| 펌웨어 (`src/main.cpp`) | ✅ 작성 완료 (NimBLE + ESP32Servo) |
| 빌드 설정 (`platformio.ini`) | ✅ 작성 완료 |
| 설치 스크립트 (win/mac/linux) | ✅ 작성 완료 |
| 웹 UI (`web/index.html`, Web Bluetooth) | ✅ 작성 완료, ⬜ 실기 검증 미완 |
| **펌웨어 빌드(`pio run`)** | ✅ **검증 완료** (Windows, PlatformIO 6.1.19, Core 3.3.7, NimBLE 2.x) |
| 설치 스크립트(windows) 실행 | ✅ 검증 완료 (.venv 생성 + pio 설치 + 빌드 성공) |
| 실제 보드 업로드/동작 검증 | ⬜ 미검증 (보드 연결 후 `pio run -t upload`) |
| BLE 클라이언트(앱) 연동 테스트 | ⬜ 미검증 |

## 2. 다음 할 일 (Next Actions)

1. 개발환경 설치 스크립트 실행 → `pio run` 으로 빌드가 통과하는지 확인.
2. 보드 연결 후 `pio run -t upload` → 시리얼 모니터에서 `[BLE] advertising` 로그 확인.
3. nRF Connect 앱으로 `ESP32C3-Servo` 접속 → Command 특성에 "90" 써서 서보 동작 확인.
4. 서보 펄스폭(`kServoMinUs`/`kServoMaxUs`)을 실제 서보에 맞게 보정.

## 3. 핵심 결정과 이유 (Decisions)

- **PlatformIO 채택**: 윈도우/맥/리눅스 동일 워크플로, 툴체인·라이브러리 자동 관리.
- **NimBLE-Arduino 2.x 채택**: ESP32-C3는 BLE 전용. NimBLE는 RAM/Flash가 적어 C3에 적합.
  현재 PlatformIO espressif32 플랫폼이 **Arduino Core 3.x(IDF5)**를 설치하므로
  **NimBLE는 반드시 2.x**여야 한다. 1.4.x는 `esp_timer_handle_t` 에러로 빌드 실패(Core 2.x 전용).
- **.ps1은 UTF-8 BOM으로 저장**: Windows PowerShell 5.1은 BOM 없는 UTF-8을 cp949로 오인 →
  한글 깨짐 + 문자열 파싱 에러. BOM이 있어야 한다(.sh는 BOM 없이 둘 것).
- **GATT 설계**: Command(Write) + Status(Notify) 2개 특성. 텍스트/바이트/명령어("CENTER","SWEEP")를 모두 허용해 범용 BLE 앱으로 테스트 가능하게 함.

## 4. 알려진 리스크 / 미해결 (Open Questions)

- 온보드 LED 핀은 보드 리비전에 따라 GPIO8이 아닐 수 있음(`kLedPin` 확인 필요).
- 서보 전원: 서보는 5V/전류 소모가 크므로 ESP32-C3 3V3 핀이 아닌 **별도 5V**에서 급전, GND 공통 연결 권장.
- `esp32-c3-devkitm-1` 보드 정의 사용 — Super Mini와 핀맵 호환되나 차이 시 `platformio.ini`에서 조정.

## 5. 빠른 참조 (Quick Reference)

- 웹 UI(배포): https://elecage.github.io/ESP32_BLE_Servo/ (GitHub Pages, main 루트 `/index.html`→`web/`)
- 웹 UI(로컬): `cd web && python -m http.server 8000` → Chrome/Edge로 `http://localhost:8000`
- 빌드: `pio run` · 업로드: `pio run -t upload` · 모니터: `pio device monitor -b 115200`
- BLE 이름: `ESP32C3-Servo`
- Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- Command(Write) UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- Status(Notify) UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a9`
- 서보 신호 핀: GPIO4
