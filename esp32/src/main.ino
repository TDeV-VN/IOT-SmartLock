
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

#define FIRMWARE_VERSION "v1.0.8"
String lockId = "lock_id1";
String uuid = "OYXo28NsfreARQqbbcecw89nspb2";

// Khai báo các hàm từ wifi_connection.cpp
void setupWifiServer();
void handleWifiClient();

// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal lcd(GPO_CONFIG::RS, GPO_CONFIG::E, GPO_CONFIG::D4, GPO_CONFIG::D5, GPO_CONFIG::D6, GPO_CONFIG::D7);

int incorrectAttempts = 0;  // Biến lưu số lần sai

unsigned long lastFirebaseUpdate = 0;
const unsigned long FIREBASE_INTERVAL = 1000; 

void setup() {
  Serial.begin(115200);

  // Khởi động LCD
  lcd.begin(16, 2);

  // Cấu hình relay và buzzer
  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);

  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Firmware " + String(FIRMWARE_VERSION));
  lcd.setCursor(0, 1);
  lcd.print("Connecting WiFi...");
  // Kết nối WiFi
  WiFi.begin("Tiến", "11012004Aa");
  // WiFi.begin("Wokwi-GUEST", "", 6);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connected to WiFi");
  delay(1000);
  lcd.clear();

  // Khởi động Firebase
  firebaseSetup(lcd);
}

void loop() {
  // Xử lý client web server
  // handleWifiClient();

  // checkPinCodeEnable(lockId);
  char key = keypad.getKey();
  if (key) {
    Serial.println("Key pressed: " + String(key));
    lcd.setCursor(0, 0);
    lcd.print("Key: " + String(key) + "        ");
    if (key == '*') {
      incorrectAttempts = handleLockControl(keypad, lcd, incorrectAttempts);
    } else if (key == '#') {
      checkAndUpdateFirmware(FIRMWARE_VERSION);
    }
  }

  // Gọi firebase định kỳ
  if (millis() - lastFirebaseUpdate > FIREBASE_INTERVAL) {
    firebaseLoop(lockId);
    lastFirebaseUpdate = millis();
  }
}

bool checkAndUpdateFirmware(const String &currentVersion) {
  HTTPClient http;
  const String infoUrl = "https://raw.githubusercontent.com/TDeV-VN/IOT-SmartLock-Firmware/firmware/latest.json";

  // Bước 1: Gửi yêu cầu HTTP GET để lấy thông tin firmware mới
  http.begin(infoUrl);
  int httpCode = http.GET();

  if (httpCode == HTTP_CODE_OK) {
    String payload = http.getString();
    Serial.println("Received data: " + payload);
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Kiem tra");
    lcd.setCursor(0, 1);
    lcd.print("cap nhat...");
    delay(1000);

    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, payload);
    if (error) {
      Serial.println("JSON parse failed!");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Loi JSON!");
      http.end();
      return false;
    }

    String latestVersion = doc["version"];
    String firmwareDownloadUrl = doc["url"];

    if (latestVersion != currentVersion) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Cap nhat");
      lcd.setCursor(0, 1);
      lcd.print("firmware...");

      http.end(); // Đóng kết nối cũ trước khi mở kết nối mới
      http.begin(firmwareDownloadUrl);
      int firmwareCode = http.GET();

      if (firmwareCode == HTTP_CODE_OK) {
        WiFiClient *client = http.getStreamPtr();
        int contentLength = http.getSize();

        if (Update.begin(contentLength)) {
          size_t written = Update.writeStream(*client);
          if (written == contentLength) {
            if (Update.end(true)) {
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("Cap nhat");
              lcd.setCursor(0, 1);
              lcd.print("thanh cong!");
              http.end();
              delay(1000); // Đợi một chút để log được in ra ổn định
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("Khoi dong lai...");
              ESP.restart(); //  Khởi động lại thiết bị
              return true;
            } else {
              Serial.println("Update.end() failed: " + String(Update.getError()));
              lcd.clear();
              lcd.setCursor(0, 0);
              lcd.print("Update failed!");
            }
          } else {
            Serial.println("Written size mismatch. Written: " + String(written));
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Write error!");
          }
        } else {
          Serial.println("Update.begin() failed.");
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Update error!");
        }
      } else {
        Serial.println("Failed to download firmware. HTTP code: " + String(firmwareCode));
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Download error!");
      }
    } else {
      Serial.println("No firmware update needed.");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("No update needed!");
    }
  } else {
    Serial.println("Failed to fetch firmware information. HTTP code: " + String(httpCode));
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Check update error!");
  }

  http.end();
  return false;
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