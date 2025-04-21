
#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include "firebase_handler.h"
#include <HTTPClient.h>            
#include <gpo_config.h>
#include "lock_control.h"
#include "WebServerHandler.h"
#include "mqtt_handler.h"

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

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Firmware " + String(FIRMWARE_VERSION));
  lcd.setCursor(0, 1);
  delay(1000);

  // // test xóa nvs
  // Preferences preferences_2;
  // preferences_2.begin("config", false);
  // preferences_2.clear();
  // preferences_2.end();

  connectwifi();

  // lcd.print("Connecting WiFi...");
  // // Kết nối WiFi
  // // WiFi.begin("Tiến", "11012004Aa");
  // // WiFi.begin("Wokwi-GUEST", "", 6);
  // while (WiFi.status() != WL_CONNECTED) {
  //   delay(500);
  // }
  // lcd.clear();
  // lcd.setCursor(0, 0);
  // lcd.print("Connected to WiFi");
  // delay(1000);
  // lcd.clear();

  // Khởi động Firebase
  firebaseSetup(lcd);

  // Khởi động MQTT
  mqttSetup(lcd);
}

void loop() {
  mqttLoop(lockId, lcd); // Gọi hàm mqttLoop để xử lý MQTT

  // tiếp tục lắng nghe đẻ nhận tín hiệu tắt AP
  extern WebServer server;
  server.handleClient();

  char key = keypad.getKey();
  if (key) {
    if (key == '*') {
      handleLockControl(keypad, lcd);
    }
  }

  // Gọi firebase định kỳ
  if (millis() - lastFirebaseUpdate > FIREBASE_INTERVAL) {
    firebaseLoop(lcd, lockId);
    lastFirebaseUpdate = millis();
  }
}

void connectwifi() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to WiFi...");

  // lấy thông tin wifi từ NVS
  Preferences preferences_1;
  preferences_1.begin("config", false);
  String ssid = preferences_1.getString("wifiSSID", "");
  String password = preferences_1.getString("wifiPassword", "");
  preferences_1.end();

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

void sendLockNotification(const String& topic, const String& title, const String& message) {
  if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[Notification] WiFi not connected!");
      return;
  }

  HTTPClient http;
  http.begin("https://iot-smartlock-firmware.onrender.com/send-topic");
  http.addHeader("Content-Type", "application/json");

  DynamicJsonDocument doc(256);
  doc["topic"] = topic;
  doc["title"] = title;
  doc["body"] = message;

  String payload;
  serializeJson(doc, payload);

  int httpCode = http.POST(payload);
  
  if (httpCode > 0) {
      Serial.printf("[Notification] Sent! Code: %d\n", httpCode);
  } else {
      Serial.printf("[Notification] Failed! Error: %s\n", http.errorToString(httpCode).c_str());
  }

  http.end();
}