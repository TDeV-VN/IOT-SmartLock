#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <gpo_config.h>
#include "lock_control.h"
#include "wifi_connection.h"  

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
}
