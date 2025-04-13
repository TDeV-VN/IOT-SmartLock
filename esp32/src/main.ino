
#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <Update.h>
#include <gpo_config.h>
#include "lock_control.h"
#include "wifi_connection.h"
#include <ArduinoJson.h>
#include <WiFi.h>
#include <NVS.h>
#include <FirebaseESP32.h>

FirebaseData firebaseData;
#define FIREBASE_HOST "slock-bb631-default-rtdb.firebaseio.com"
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

  // Khởi động Wi-Fi Server:
  startServer();  // Khởi động điểm truy cập và WebServer
}

void loop() {
  // Xử lý client web server
  handleWifiClient();

  char key = keypad.getKey();
  if (key == '*') {
    // Truyền giá trị incorrectAttempts vào hàm và nhận giá trị trả về
    Serial.println("Số lần sai trước khi nhập mã: " + String(incorrectAttempts));
    incorrectAttempts = handleLockControl(keypad, lcd, incorrectAttempts);  
    Serial.println("Số lần sai sau khi nhập mã: " + String(incorrectAttempts));  // In số lần sai sau khi nhập mã
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


void resetAndClearData(const String& lock_id) {
  // 1. Xóa dữ liệu liên quan đến lock_id trong Firebase Realtime Database
  String path = "/lock/" + lock_id;  // Đường dẫn đến dữ liệu lock_id
  if (Firebase.delete(firebaseData, path)) {
    Serial.println("Firebase data for lock_id deleted successfully.");
  } else {
    Serial.print("Failed to delete data from Firebase: ");
    Serial.println(firebaseData.errorReason());
  }

  // 2. Xóa toàn bộ dữ liệu trong NVS (Non-Volatile Storage)
  NVS.begin("storage", false);  // Mở NVS với tên "storage"
  NVS.eraseAll();  // Xóa toàn bộ dữ liệu trong NVS
  Serial.println("All NVS data erased.");

  // 3. Reset ESP32
  Serial.println("Resetting ESP32...");
  ESP.restart();  // Khởi động lại ESP32
}