# 세션 로그 (Session Log)

> 시간순 **누적(append-only)** 이력. 새 항목은 맨 위에 추가합니다.
> 각 세션 종료 시 [TEMPLATE.md](handoff/TEMPLATE.md) 형식으로 한 항목을 추가하고,
> 최신 상태는 [HANDOFF.md](HANDOFF.md)에 반영합니다.

---

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
