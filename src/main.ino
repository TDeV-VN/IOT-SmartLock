#include <Arduino.h>

#ifndef LED_BUILTIN
#define LED_BUILTIN 2  // Thường là chân 2, nhưng có thể khác tùy vào board
#endif

void setup() {
  // Khởi tạo chân LED_BUILTIN là OUTPUT
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // Bật đèn LED
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);  // Giữ sáng 500ms

  // Tắt đèn LED
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);  // Giữ tắt 500ms
}