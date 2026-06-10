# 세션 로그 (Session Log)

> 시간순 **누적(append-only)** 이력. 새 항목은 맨 위에 추가합니다.
> 각 세션 종료 시 [TEMPLATE.md](handoff/TEMPLATE.md) 형식으로 한 항목을 추가하고,
> 최신 상태는 [HANDOFF.md](HANDOFF.md)에 반영합니다.

---

## 2026-06-10 — 설치 스크립트 venv 격리로 변경
- **작업자:** Claude
- **목표:** PlatformIO를 시스템이 아닌 프로젝트 로컬 venv에 설치(요청).
- **한 일:**
  - 3개 스크립트(win/mac/linux)를 `.venv` 생성 → `pip install platformio` 방식으로 변경.
    (기존 get-platformio.py 글로벌 설치 방식 대체)
  - `.gitignore`에 `.venv/` 추가. README/CLAUDE.md에 활성화·직접호출 안내 반영.
- **사용:** `source .venv/bin/activate`(mac/linux) / `.\.venv\Scripts\Activate.ps1`(win)
  또는 `./.venv/bin/pio ...` 직접 호출.
- **검증:** ⬜ 스크립트 실기 실행 미검증(보드/PC에서 1회 실행 권장).

## 2026-06-10 — GitHub Pages 배포
- **작업자:** Claude
- **한 일:** 저장소 public 전환, 루트 `index.html`(→`web/` 리다이렉트) 추가,
  GitHub Pages 활성화(main 루트). 배포 URL: https://elecage.github.io/ESP32_BLE_Servo/
  → 폰/PC 브라우저에서 https로 바로 BLE 제어 가능.
- **검증:** 루트/web 경로 HTTP 200 확인. ⬜ 실제 BLE 제어는 보드 연결 후 확인 필요.

## 2026-06-10 — 웹 UI(Web Bluetooth) 추가
- **작업자:** Claude
- **목표:** 스마트폰 BLE 앱 대신 브라우저에서 슬라이더/버튼으로 서보 제어.
- **한 일:**
  - `web/index.html` 작성 — Web Bluetooth API로 ESP32에 직접 연결.
    슬라이더(쓰로틀 쓰기), 프리셋(0/45/90/135/180), CENTER/SWEEP, 직접 명령,
    Status Notify 수신/로그. 펌웨어와 동일 UUID·텍스트 명령 사용(펌웨어 변경 없음).
  - README에 웹 UI 사용법, HANDOFF에 상태 반영.
- **결정:** Web Bluetooth 채택 — 앱 설치 불필요, 데스크톱/안드로이드 Chrome·Edge 지원.
  단 보안 컨텍스트 필요(localhost/https), iOS는 Bluefy 필요 → 문서에 명시.
- **검증:** ⬜ 실제 보드와 브라우저 연결 미검증.
- **다음 세션 인계:** 보드 업로드 후 `localhost:8000`에서 연결/슬라이더 동작 확인.

## 2026-06-10 — git 저장소 초기화 & GitHub 푸시
- **작업자:** Claude
- **한 일:** `git init`(main), `.gitattributes`로 줄바꿈 고정, 초기 커밋,
  private 저장소 `elecage/ESP32_BLE_Servo` 생성 후 push.

## 2026-06-10 — 초기 프로젝트 구축
- **작업자:** Claude
- **목표:** ESP32-C3 Super Mini BLE 서보 제어 프로젝트 초기 구축.
- **한 일:**
  - `src/main.cpp` 작성 — NimBLE GATT 서버 + ESP32Servo, Command/Status 특성.
  - `platformio.ini` 작성 — esp32-c3-devkitm-1, USB-CDC, NimBLE/ESP32Servo 의존성.
  - `scripts/setup_windows.ps1`, `setup_macos.sh`, `setup_linux.sh` 작성.
  - `CLAUDE.md` 및 인수인계 문서 체계(`docs/`) 구성.
- **결정:** PlatformIO + NimBLE 채택(사유는 HANDOFF.md 참조).
- **검증:** ⬜ 실제 보드 빌드/업로드 미검증.
- **다음 세션 인계:** 보드 연결 후 빌드→업로드→BLE 앱 동작 확인. (HANDOFF.md "다음 할 일" 참조)
