
#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <WiFi.h>
#include "firebase_handler.h"
#include <HTTPClient.h>     
#include <ArduinoJson.h>        
#include <Update.h>
#include <gpo_config.h>
#include "lock_control.h"
#include "wifi_connection.h"

#define FIRMWARE_VERSION "1.0.2"
String lockId = "lock_id1";

// Khai báo các hàm từ wifi_connection.cpp
void setupWifiServer();
void handleWifiClient();

// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal lcd(GPO_CONFIG::RS, GPO_CONFIG::E, GPO_CONFIG::D4, GPO_CONFIG::D5, GPO_CONFIG::D6, GPO_CONFIG::D7);

int incorrectAttempts = 0;  // Biến lưu số lần sai

void setup() {
  Serial.begin(115200);

  // Khởi động LCD
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("HELLO MY FRIEND!");
  lcd.setCursor(0, 1);
  lcd.print("* to enter code");

  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);  // relay OFF
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
}

void loop() {
  // Xử lý client web server
  handleWifiClient();

  char key = keypad.getKey();
  if (key == '*') {
    // Truyền giá trị incorrectAttempts vào hàm và nhận giá trị trả về
    Serial.println("Số lần sai trước khi nhập mã: " + String(incorrectAttempts));
    incorrectAttempts = handleLockControl(keypad, lcd, incorrectAttempts);  
    Serial.println("Số lần sai sau khi nhập mã 1: " + String(incorrectAttempts));
  }
  //check update
  // String currentVersion = "1.0.0";  // Thay thế bằng phiên bản hiện tại của firmware
  // bool success = checkAndUpdateFirmware(currentVersion);
  // if (success) {
  //   Serial.println("Firmware update successful.");
  // } else {
  //   Serial.println("Firmware update failed.");
  // }

}

bool checkAndUpdateFirmware(const String &currentVersion) {
  HTTPClient http;
  String firmwareUrl = "https://raw.githubusercontent.com/TDeV-VN/IOT-SmartLock-Firmware/firmware/latest.json";

  // Gửi yêu cầu HTTP GET để tải file JSON
  http.begin(firmwareUrl);
  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    Serial.println("Received data: " + payload);

    // Phân tích dữ liệu JSON để lấy version và URL firmware mới
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, payload);
    String latestVersion = doc["version"];
    String firmwareDownloadUrl = doc["url"];

    Serial.println("Current Version: " + currentVersion);
    Serial.println("Latest Version: " + latestVersion);

    if (latestVersion != currentVersion) {
      Serial.println("Firmware update available. Starting download...");
      
      // Tải firmware mới
      http.begin(firmwareDownloadUrl);
      int firmwareCode = http.GET();
      if (firmwareCode == HTTP_CODE_OK) {
        WiFiClient *client = http.getStreamPtr();
        if (Update.begin(client->available())) {
          // Tiến hành cập nhật firmware
          size_t written = Update.writeStream(*client);
          if (written == client->available()) {
            if (Update.end(true)) {
              Serial.println("Firmware updated successfully.");
              return true;
            } else {
              Serial.println("Failed to commit firmware update.");
            }
          } else {
            Serial.println("Failed to write firmware data.");
          }
        }
      } else {
        Serial.println("Failed to download firmware.");
      }
    } else {
      Serial.println("No firmware update needed.");
    }
  } else {
    Serial.println("Failed to fetch firmware information.");
  }

  http.end(); // Đóng kết nối HTTP
  return false; // Trả về false nếu có lỗi
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