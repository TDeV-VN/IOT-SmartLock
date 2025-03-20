#include <Keypad.h>

const byte ROWS = 4; // Số hàng
const byte COLS = 4; // Số cột

char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

byte rowPins[ROWS] = {13, 12, 14, 27}; // Chân hàng nối ESP32
byte colPins[COLS] = {26, 25, 33, 32}; // Chân cột nối ESP32

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

void setup() {
  Serial.begin(115200);
  Serial.println("Nhap phim tu ban phim ma tran:");
}

void loop() {
  char key = keypad.getKey();
  if (key) {
    Serial.print("Phim nhan: ");
    Serial.println(key);
  }
}