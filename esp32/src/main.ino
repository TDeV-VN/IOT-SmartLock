#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal.h>
#include <gpo_config.h>
#include "lock_control.h" 

// Khai báo các hàm từ wifi_connection.cpp
void setupWifiServer();
void handleWifiClient();

// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal lcd(GPO_CONFIG::RS, GPO_CONFIG::E, GPO_CONFIG::D4, GPO_CONFIG::D5, GPO_CONFIG::D6, GPO_CONFIG::D7);

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

  // Thêm dòng này để khởi động WiFi Server:
  setupWifiServer();
}

void loop() {
  // Thêm dòng này để xử lý client web server:
  handleWifiClient();

  char key = keypad.getKey();
  if (key == '*') {
    handleLockControl(keypad, lcd);  // Gọi hàm xử lý mã khóa
  }
}
