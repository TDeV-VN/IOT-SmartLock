#include <Keypad.h>
#include <LiquidCrystal.h>
#include <gpo_config.h>

// Khai báo bàn phím ma trận
Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);

// Khai báo LCD 16x2
LiquidCrystal lcd(GPO_CONFIG::RS, GPO_CONFIG::E, GPO_CONFIG::D4, GPO_CONFIG::D5, GPO_CONFIG::D6, GPO_CONFIG::D7);

void setup() {
  Serial.begin(115200);
  Serial.println("Nhap phim tu ban phim ma tran:");

  // Khởi động LCD
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("ESP32 Keypad Test");

  // Cấu hình relay
  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // Ban đầu tắt relay (nếu relay dùng LOW level trigger)
  
  // Cấu hình buzzer
  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);
}

void loop() {
  char key = keypad.getKey();
  
  if (key) {
    Serial.print("Phim nhan: ");
    Serial.println(key);
    
    lcd.setCursor(0, 1);
    lcd.print("Phim: ");
    lcd.print(key);
    lcd.print("    "); // Xóa kí tự cũ

    // Bật buzzer khi nhấn phím bất kỳ
    digitalWrite(GPO_CONFIG::BUZZER_PIN, HIGH);
    delay(200);
    digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);

    if (key == 'A') {
      // Mở khóa
      Serial.println("Mo khoa trong 5s...");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Mo khoa...");
      
      digitalWrite(GPO_CONFIG::RELAY_PIN, LOW); // Bật relay (nếu là relay LOW-level trigger)
      delay(5000); // Giữ relay bật trong 5 giây
      digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // Tắt relay
      Serial.println("Khoa dong!");
      
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Khoa dong!");
    }

    if (key == 'B') {
      // Đóng khóa ngay lập tức
      Serial.println("Khoa dong ngay lap tuc!");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Khoa dong!");
      digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // Tắt relay ngay lập tức
    }

    if (key == '#') {
      // Xóa màn hình khi nhấn "#"
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("ESP32 Keypad Test");
    }
  }
}
