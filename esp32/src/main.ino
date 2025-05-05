
#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include "firebase_handler.h"          
#include <gpo_config.h>
#include "lock_control.h"
#include "WebServerHandler.h"
#include "mqtt_handler.h"
#include <Preferences.h>


extern Preferences preferences;
TaskHandle_t buzzerTaskHandle = NULL;
TaskHandle_t relayTaskHandle = NULL;

#define FIRMWARE_VERSION getFirmwareVersion()
String lockId = getLockId();

// Khai báo các hàm từ wifi_connection.cpp
void setupWifiServer();
void handleWifiClient();

// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal_I2C lcd(0x27, 16, 2);

unsigned long lastFirebaseUpdate = 0;
const unsigned long FIREBASE_INTERVAL = 1000; 

// --- Biến cho logic nhấn giữ phím # ---
bool hashKeyHeld = false;            // Cờ báo phím # đang được giữ
unsigned long hashKeyPressStartTime = 0; // Thời điểm bắt đầu nhấn #
const unsigned long HASH_HOLD_DURATION = 5000; // 5 giây (5000ms)
bool resetTriggered = false;         // Cờ để tránh gọi reset nhiều lần
// ------------------------------------

void setup() {
  Serial.begin(115200);

  // Khởi động LCD
  lcd.init();
  lcd.backlight();

  // Cấu hình relay và buzzer
  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);

  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Firmware " + String(FIRMWARE_VERSION));
  lcd.setCursor(0, 1);
  delay(1000);

  // Tạo task điều khiển buzzer
  xTaskCreate(
    buzzerTask,          // Hàm thực thi của task
    "BuzzerTask",        // Tên task (dùng để debug)
    2048,                // Kích thước stack (bytes) - điều chỉnh nếu cần
    NULL,                // Tham số truyền vào task (không cần trong trường hợp này)
    1,                   // Độ ưu tiên (0 là thấp nhất)
    &buzzerTaskHandle   // Handle để điều khiển task
  );


  if (buzzerTaskHandle == NULL) {
    Serial.println("Failed to create Buzzer Task!");
  } else {
    Serial.println("Buzzer Task created successfully.");
  }

  // Kết nối WiFi
  #ifdef WOKWI_SIMULATION
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wokwi Simulation");
    delay(1000);
    lcd.clear();
    // Nếu đang chạy trên Wokwi, sử dụng WiFi.begin() với thông tin mạng Wokwi-GUEST
    lcd.clear();
    lcd.print("Connecting WiFi...");
    WiFi.begin("Wokwi-GUEST", "", 6);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
    }
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connected to WiFi");
    delay(1000);
    lcd.clear();
  #else
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Physical Device");
    delay(1000);
    lcd.clear();
    // Nếu không phải trên Wokwi, sử dụng thông tin từ NVS hoặc từ người dùng
    connectwifi();
  #endif

  // Cấu hình NTP
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov"); // GMT+7 (7 * 3600 giây)
  Serial.println("Waiting for NTP time sync...");
  lcd.setCursor(0, 0);
  lcd.print("Waiting for NTP");

  // Chờ đồng bộ thời gian
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) { // Kiểm tra nếu thời gian chưa được đồng bộ
      delay(500);
      Serial.print(".");
      now = time(nullptr);
  }

  // Khởi động Firebase
  firebaseSetup(lcd);

  // Khởi động MQTT
  mqttSetup(lcd);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("San sang");
  lcd.setCursor(0, 1);
  lcd.print("hoat dong!");
  delay(1000);
  lcd.clear();
}

void loop() {
  // nếu mất wifi thì kết nối lại từ NVS
  if (WiFi.status() != WL_CONNECTED) {
    preferences.begin("config", false);
    String ssid = preferences.getString("wifiSSID", "");
    String password = preferences.getString("wifiPassword", "");
    preferences.end();
    
    WiFi.begin(ssid.c_str(), password.c_str());
  }

  mqttLoop(lockId, lcd); // Gọi hàm mqttLoop để xử lý MQTT

  // tiếp tục lắng nghe đẻ nhận tín hiệu tắt AP
  extern WebServer server;
  server.handleClient();

   // --- Xử lý Keypad với logic nhấn giữ ---
  // Lấy trạng thái hiện tại của các phím (quan trọng cho việc phát hiện nhấn và nhả)
  if (keypad.getKeys()) {
    for (int i = 0; i < LIST_MAX; i++) { // LIST_MAX thường là 10 trong thư viện Keypad
        if (keypad.key[i].stateChanged) { // Chỉ xử lý khi trạng thái phím thay đổi
            char currentKey = keypad.key[i].kchar;
            KeyState currentState = keypad.key[i].kstate;

            if (currentKey == '#') {
                if (currentState == PRESSED) {
                    Serial.println("Key '#' PRESSED");
                    hashKeyHeld = true;
                    hashKeyPressStartTime = millis();
                    resetTriggered = false; // Reset cờ trigger khi bắt đầu nhấn mới
                    // Có thể hiển thị gì đó lên LCD báo hiệu đang giữ phím #
                    lcd.clear();
                    lcd.print("Giu # de reset");
                } else if (currentState == RELEASED) {
                    Serial.println("Key '#' RELEASED");
                    hashKeyHeld = false;
                    hashKeyPressStartTime = 0;
                    if (!resetTriggered) { // Chỉ xóa LCD nếu chưa trigger reset
                       lcd.clear(); // Xóa thông báo giữ phím
                    }
                }
            } else if (currentKey == '*') {
                 if (currentState == PRESSED) { // Chỉ xử lý khi nhấn *
                     Serial.println("Key '*' PRESSED");
                     // Dừng kiểm tra nhấn giữ # nếu đang nhấn *
                     if (hashKeyHeld) {
                         hashKeyHeld = false;
                         hashKeyPressStartTime = 0;
                         lcd.clear();
                     }
                     handleLockControl(keypad, lcd, false); // Gọi hàm xử lý mã khóa
                 }
            }
            // Xử lý các phím khác nếu cần
        }
    }
} // kết thúc if (keypad.getKeys())

// --- Kiểm tra logic nhấn giữ # liên tục trong loop ---
if (hashKeyHeld && !resetTriggered) {
    unsigned long heldDuration = millis() - hashKeyPressStartTime; // Thời gian đã giữ (heldDuration)

    if (heldDuration >= HASH_HOLD_DURATION) {
        Serial.println("Key '#' held for 5 seconds. Triggering reset...");

        resetTriggered = true; // Đánh dấu đã trigger để tránh gọi lại
        hashKeyHeld = false; // Ngừng trạng thái nhấn giữ
        handleLockControl(keypad, lcd, true); // Gọi hàm reset khóa
    }
}
// --------------------------------------------------

  // Gọi firebase định kỳ
  if (millis() - lastFirebaseUpdate > FIREBASE_INTERVAL) {
    firebaseLoop(lcd, lockId);
    lastFirebaseUpdate = millis();
  }
}

void resetLock() {
  Serial.println("##### RESET LOCK FUNCTION CALLED! #####");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Resetting lock...");
  delay(2000);
  lcd.clear();
  
  // xóa dữ liệu trong NVS
  preferences.begin("config", false);
  preferences.clear(); // xóa toàn bộ dữ liệu trong NVS
  preferences.end();
  delay(1000);
  preferences.begin("PinCodeEnable", false);
  preferences.clear(); // xóa toàn bộ dữ liệu trong NVS
  preferences.end();
  delay(1000);

  // xóa dư liệu trong Firebase
  if (resetLockDataForAllUsers(lockId)) {
    lcd.setCursor(0, 0);
    lcd.print("Reset lock data");
    lcd.setCursor(0, 1);
    lcd.print("successfully!");
  } else {
    lcd.setCursor(0, 0);
    lcd.print("Reset lock data");
    lcd.setCursor(0, 1);
    lcd.print("failed!");
  }

  // khởi động lại thiết bị
  ESP.restart();
}

void connectwifi() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to WiFi...");

  // lấy thông tin wifi từ NVS
  preferences.begin("config", false);
  String ssid = preferences.getString("wifiSSID", "");
  String password = preferences.getString("wifiPassword", "");
  preferences.end();

  // thử kết nối wifi với thông tin đã lưu
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to");
  lcd.setCursor(0, 1);
  lcd.print(ssid + "...");
  
  WiFi.begin(ssid.c_str(), password.c_str());
  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    retry++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connected to");
    lcd.setCursor(0, 1);
    lcd.print(ssid + "!");
    delay(1000);
  } else {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Failed to reconnect");
    delay(2000);

    // mở AP mode nếu không kết nối được wifi
    startServer(lcd);
    while (WiFi.status() != WL_CONNECTED) {
      extern WebServer server;
      server.handleClient();
      delay(500);
    }
  }
  lcd.clear();
}

