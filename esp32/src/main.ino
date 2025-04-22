
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

  connectwifi();

  // lcd.print("Connecting WiFi...");
  // Kết nối WiFi
  // WiFi.begin("Tiến", "11012004Aa");
  // WiFi.begin("Wokwi-GUEST", "", 6);
  // while (WiFi.status() != WL_CONNECTED) {
  //   delay(500);
  // }
  // lcd.clear();
  // lcd.setCursor(0, 0);
  // lcd.print("Connected to WiFi");
  // delay(1000);
  // lcd.clear();

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

  char key = keypad.getKey();
  if (key) {
    if (key == '*') {
      handleLockControl(keypad, lcd);
    } else if (key == '#') {
      resetLock(); // gọi hàm reset khóa
    } 
  }

  // Gọi firebase định kỳ
  if (millis() - lastFirebaseUpdate > FIREBASE_INTERVAL) {
    firebaseLoop(lcd, lockId);
    lastFirebaseUpdate = millis();
  }
}

void resetLock() {
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

