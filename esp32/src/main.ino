#include <Keypad.h>
#include <LiquidCrystal.h>

// Khai báo bàn phím ma trận 4x4
const byte ROWS = 4;
const byte COLS = 4;

char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

byte rowPins[ROWS] = {13, 12, 14, 27};
byte colPins[COLS] = {26, 25, 33, 32};

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

// Khai báo LCD 16x2
#define RS  23
#define E   19
#define D4  18
#define D5  17
#define D6  16
#define D7  15

LiquidCrystal lcd(RS, E, D4, D5, D6, D7);

void setup() {
  Serial.begin(115200);
  Serial.println("Nhap phim tu ban phim ma tran:");

  // Khởi động LCD
  lcd.begin(16, 2);
  lcd.setCursor(0, 0);
  lcd.print("ESP32 Keypad Test");
}

void loop() {
  char key = keypad.getKey();
  
  if (key) {
    Serial.print("Phim nhan: ");
    Serial.println(key);
    
    if (key == '#') {
      // Xóa màn hình khi nhấn "#"
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("ESP32 Keypad Test");
    } else {
      // Hiển thị phím nhấn lên dòng thứ hai của LCD
      lcd.setCursor(0, 1);
      lcd.print("Phim: ");
      lcd.print(key);
    }
  }
}