#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <gpo_config.h>
#include "lock_control.h" 
#include <WiFi.h>
#include "firebase_handler.h"
#include <HTTPClient.h>          // Thêm thư viện HTTPClient
#include <ArduinoJson.h>         // Thêm thư viện ArduinoJson

#define FIRMWARE_VERSION "1.0.2"

// Khai báo các hàm từ wifi_connection.cpp
void setupWifiServer();
void handleWifiClient();

String lockId = "lock_id1";
// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal lcd(GPO_CONFIG::RS, GPO_CONFIG::E, GPO_CONFIG::D4, GPO_CONFIG::D5, GPO_CONFIG::D6, GPO_CONFIG::D7);

int incorrectAttempts = 0;  // Biến lưu số lần sai

// ========= THÊM HÀM GỬI THÔNG BÁO ========= //
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
// ========= HẾT PHẦN THÊM ========= //

void setup() {
  Serial.begin(115200);

  // Khởi động LCD
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("HELLO MY FRIEND!");
  lcd.setCursor(0, 1);
  lcd.print("* to enter code");

  // Cấu hình relay
  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // relay OFF

  // Cấu hình buzzer
  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);

  // Kết nối wifi
  WiFi.begin("Wokwi-GUEST", "", 6);
  Serial.print("Dang ket noi wifi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nWifi da ket noi!");
  
  firebaseSetup();

  // ======= GỬI THÔNG BÁO KHI KHỞI ĐỘNG ======= //
  sendLockNotification(
    "SystemStart",
    "Khởi động hệ thống",
    "Khóa cửa " + lockId + " đã khởi động. Phiên bản " + FIRMWARE_VERSION
  );
}

void loop() {
  // Thêm dòng này để xử lý client web server:
  // handleWifiClient();

  char key = keypad.getKey();
  if (key == '*') {
    // Truyền giá trị incorrectAttempts vào hàm và nhận giá trị trả về
    Serial.println("Số lần sai sau khi nhập mã: " + String(incorrectAttempts));
    incorrectAttempts = handleLockControl(keypad, lcd, incorrectAttempts);  
    Serial.println("Số lần sai sau khi nhập mã 1: " + String(incorrectAttempts));
    
    // ======= GỬI THÔNG BÁO KHI NHẬP SAI ======= //
    if (incorrectAttempts >= 3) {
      sendLockNotification(
        "SecurityAlert",
        "Cảnh báo an ninh",
        "Khóa " + lockId + " nhập sai mã " + String(incorrectAttempts) + " lần"
      );
    }
  }

  // Firebase loop không chặn chương trình
  firebaseLoop(lockId);
}