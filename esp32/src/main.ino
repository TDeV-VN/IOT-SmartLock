
#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <WiFi.h>
<<<<<<< HEAD
#include "firebase_handler.h"
#include <HTTPClient.h>          // Thêm thư viện HTTPClient
#include <ArduinoJson.h>         // Thêm thư viện ArduinoJson
=======
#include <HTTPClient.h>
#include <Update.h>
#include <gpo_config.h>
#include "lock_control.h"
#include "wifi_connection.h"
#include <ArduinoJson.h>
>>>>>>> 5f106347827ed02265842d8f788d9d51f9928bcb

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

  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);  // relay OFF
  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);

<<<<<<< HEAD
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
=======
  // Khởi động Wi-Fi Server:
  startServer();  // Khởi động điểm truy cập và WebServer
>>>>>>> 5f106347827ed02265842d8f788d9d51f9928bcb
}

void loop() {
  // Xử lý client web server
  handleWifiClient();

  char key = keypad.getKey();
  if (key == '*') {
    // Truyền giá trị incorrectAttempts vào hàm và nhận giá trị trả về
    Serial.println("Số lần sai trước khi nhập mã: " + String(incorrectAttempts));
    incorrectAttempts = handleLockControl(keypad, lcd, incorrectAttempts);  
<<<<<<< HEAD
    Serial.println("Số lần sai sau khi nhập mã 1: " + String(incorrectAttempts));
    
    // ======= GỬI THÔNG BÁO KHI NHẬP SAI ======= //
    if (incorrectAttempts >= 3) {
      sendLockNotification(
        "SecurityAlert",
        "Cảnh báo an ninh",
        "Khóa " + lockId + " nhập sai mã " + String(incorrectAttempts) + " lần"
      );
    }
=======
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
>>>>>>> 5f106347827ed02265842d8f788d9d51f9928bcb
  }

  http.end(); // Đóng kết nối HTTP
  return false; // Trả về false nếu có lỗi
}

