/**
 * ESP32-C3 Super Mini — BLE Servo Controller
 * ------------------------------------------------------------
 * BLE로 접속한 클라이언트가 서보모터의 각도(0~180°)를 제어합니다.
 *
 * ESP32-C3는 Bluetooth Classic을 지원하지 않고 BLE(GATT)만 지원하므로
 * NimBLE-Arduino 스택을 사용합니다(메모리 사용량이 적어 C3에 적합).
 *
 * GATT 구조
 *   Service        : 4fafc201-1fb5-459e-8fcc-c5c9c331914b
 *   ├─ Command Char (Write / WriteNR) : beb5483e-36e1-4688-b7f5-ea07361b26a8
 *   │     아래 형식의 값을 쓰면 동작합니다.
 *   │       - 1바이트 정수 (0~180)         : 해당 각도로 이동
 *   │       - ASCII 문자열 "90"            : 해당 각도로 이동
 *   │       - "CENTER"                     : 90도로 이동
 *   │       - "SWEEP"                      : 0→180→0 스윕 1회
 *   └─ Status Char  (Read / Notify)        : beb5483e-36e1-4688-b7f5-ea07361b26a9
 *         현재 각도를 "ANGLE:90" 형태의 문자열로 통지(notify)합니다.
 *
 * 테스트: 스마트폰 nRF Connect 앱으로 위 Service에 접속 후 Command Char에
 *         텍스트 "90"을 쓰면 서보가 90도로 움직입니다.
 */

#include <Arduino.h>
#include <NimBLEDevice.h>
#include <ESP32Servo.h>

// ----------------------------------------------------------------------------
// 사용자 설정 (보드/배선에 맞게 조정)
// ----------------------------------------------------------------------------
static const char* kDeviceName = "ESP32C3-Servo";

static const int   kServoPin   = 4;    // 서보 신호선(주황) 연결 GPIO
static const int   kLedPin     = 8;    // 온보드 LED(대부분의 C3 Super Mini는 GPIO8, active-low)
static const bool  kLedActiveLow = true;

static const int   kServoMinUs = 500;  // 0도 펄스폭(us) — 서보에 맞게 보정
static const int   kServoMaxUs = 2400; // 180도 펄스폭(us)
static const int   kServoMinDeg = 0;
static const int   kServoMaxDeg = 180;

// BLE UUID
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CMD_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define STATUS_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// ----------------------------------------------------------------------------
// 전역 상태
// ----------------------------------------------------------------------------
Servo                   servo;
NimBLEServer*           g_server      = nullptr;
NimBLECharacteristic*   g_statusChar  = nullptr;
volatile bool           g_connected   = false;
int                     g_currentDeg  = 90;

// ----------------------------------------------------------------------------
// 헬퍼
// ----------------------------------------------------------------------------
static void setLed(bool on) {
  digitalWrite(kLedPin, (on ^ kLedActiveLow) ? HIGH : LOW);
}

static int clampDeg(int deg) {
  if (deg < kServoMinDeg) return kServoMinDeg;
  if (deg > kServoMaxDeg) return kServoMaxDeg;
  return deg;
}

static void notifyStatus() {
  if (!g_statusChar) return;
  char buf[16];
  snprintf(buf, sizeof(buf), "ANGLE:%d", g_currentDeg);
  g_statusChar->setValue((uint8_t*)buf, strlen(buf));
  if (g_connected) g_statusChar->notify();
}

static void moveTo(int deg) {
  g_currentDeg = clampDeg(deg);
  servo.write(g_currentDeg);
  Serial.printf("[SERVO] -> %d deg\n", g_currentDeg);
  notifyStatus();
}

static void sweepOnce() {
  Serial.println("[SERVO] sweep");
  for (int d = kServoMinDeg; d <= kServoMaxDeg; d += 5) { servo.write(d); delay(15); }
  for (int d = kServoMaxDeg; d >= kServoMinDeg; d -= 5) { servo.write(d); delay(15); }
  moveTo(90);
}

// 쓰여진 값을 해석해서 서보를 동작시킨다.
static void handleCommand(const std::string& raw) {
  if (raw.empty()) return;

  // 1) 순수 1바이트 바이너리 각도 (제어문자가 아닌 ASCII 숫자가 아닌 경우)
  if (raw.size() == 1 && (uint8_t)raw[0] <= 180 && !isdigit((uint8_t)raw[0])) {
    moveTo((uint8_t)raw[0]);
    return;
  }

  // 2) 문자열 명령
  std::string s = raw;
  // 트림
  while (!s.empty() && (s.back() == '\r' || s.back() == '\n' || s.back() == ' ')) s.pop_back();
  std::string up = s;
  for (auto& c : up) c = toupper((unsigned char)c);

  if (up == "CENTER") { moveTo(90); return; }
  if (up == "SWEEP")  { sweepOnce(); return; }

  // 3) ASCII 정수 문자열 "0".."180"
  bool numeric = !s.empty();
  for (char c : s) if (!isdigit((unsigned char)c)) { numeric = false; break; }
  if (numeric) { moveTo(atoi(s.c_str())); return; }

  Serial.printf("[BLE] unknown command: '%s'\n", s.c_str());
}

// ----------------------------------------------------------------------------
// BLE 콜백
// ----------------------------------------------------------------------------
// NimBLE 2.x 콜백 시그니처(NimBLEConnInfo&, onDisconnect는 reason 포함)
class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* server, NimBLEConnInfo& connInfo) override {
    g_connected = true;
    setLed(true);
    Serial.println("[BLE] client connected");
  }
  void onDisconnect(NimBLEServer* server, NimBLEConnInfo& connInfo, int reason) override {
    g_connected = false;
    setLed(false);
    Serial.printf("[BLE] client disconnected (reason %d) — restart advertising\n", reason);
    NimBLEDevice::startAdvertising();
  }
};

class CmdCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* chr, NimBLEConnInfo& connInfo) override {
    // 바이너리 안전하게 길이 기반으로 읽는다(0x00 바이트 포함 가능)
    NimBLEAttValue v = chr->getValue();
    handleCommand(std::string((const char*)v.data(), v.length()));
  }
};

// ----------------------------------------------------------------------------
// setup / loop
// ----------------------------------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("\n[BOOT] ESP32-C3 BLE Servo Controller");

  pinMode(kLedPin, OUTPUT);
  setLed(false);

  // 서보 초기화 (ESP32Servo는 내부적으로 LEDC PWM 타이머 사용)
  ESP32PWM::allocateTimer(0);
  servo.setPeriodHertz(50);                         // 표준 서보 50Hz
  servo.attach(kServoPin, kServoMinUs, kServoMaxUs);
  servo.write(g_currentDeg);

  // BLE 초기화
  NimBLEDevice::init(kDeviceName);
  NimBLEDevice::setPower(9);                         // 송신 출력 +9dBm (NimBLE 2.x: dBm 직접 지정)

  g_server = NimBLEDevice::createServer();
  g_server->setCallbacks(new ServerCallbacks());

  NimBLEService* service = g_server->createService(SERVICE_UUID);

  NimBLECharacteristic* cmdChar = service->createCharacteristic(
      CMD_CHAR_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  cmdChar->setCallbacks(new CmdCallbacks());

  g_statusChar = service->createCharacteristic(
      STATUS_CHAR_UUID,
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  notifyStatus();

  service->start();

  NimBLEAdvertising* adv = NimBLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->enableScanResponse(true);                    // NimBLE 2.x: setScanResponse → enableScanResponse
  NimBLEDevice::startAdvertising();

  Serial.printf("[BLE] advertising as '%s'\n", kDeviceName);
}

void loop() {
  // 연결 대기 중에는 LED를 느리게 깜빡여 동작 표시
  if (!g_connected) {
    static uint32_t last = 0;
    static bool on = false;
    if (millis() - last > 500) {
      last = millis();
      on = !on;
      setLed(on);
    }
  }
  delay(10);
}
