#include <Keypad.h>
#include <LiquidCrystal.h>
#include <Preferences.h>  
#include <gpo_config.h>

Preferences preferences;
// int incorrectAttempts; // Số lần nhập sai
String enteredPassword = ""; // Mã khóa nhập vào

// Mã khóa mặc định
const String correctPassword = "1111";

// Cấu hình timeout
const unsigned long timeoutDuration = 60000; // 1 phút (60,000 ms)
const unsigned long wrongAttemptResetDuration = 1800000; // 30 phút (1,800,000 ms)

// Khai báo thời gian sai cuối cùng và thời gian nhấn phím cuối cùng
static unsigned long lastWrongAttemptTime = 0; // Biến lưu thời gian của lần thử sai cuối cùng
static unsigned long lastKeypressTime = 0; // Biến lưu thời gian nhấn phím cuối cùng
int handleLockControl(Keypad &keypad, LiquidCrystal &lcd, int incorrectAttempts) {
    preferences.begin("config", false);
    incorrectAttempts = preferences.getInt("incorrectAttempts", incorrectAttempts);  // Đọc lại số lần sai từ NVS
    Serial.println("Số lần sai: " + String(incorrectAttempts));  // In số lần sai từ NVS
    preferences.end();

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Nhap ma khoa");
    enteredPassword = "";
    lastKeypressTime = millis();

    while (true) {
        char key = keypad.getKey();
        unsigned long currentMillis = millis();

        // Thoát nếu quá timeout
        if (currentMillis - lastKeypressTime > timeoutDuration) {
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Het thoi gian!");
            delay(1500);
            lcd.clear();
            enteredPassword = "";
            return incorrectAttempts;  // Trả về số lần sai hiện tại
        }

        if (key) {
            lastKeypressTime = currentMillis;

            if (key == '#') {
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("Thoat!");
                delay(1500);
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("HELLO MY FRIEND!");
                lcd.setCursor(0, 1);
                lcd.print("* to enter code");

                enteredPassword = "";
                return incorrectAttempts;  // Thoát chế độ nhập mã mà không reset incorrectAttempts
            }

            enteredPassword += key;

            lcd.setCursor(0, 1);
            for (int i = 0; i < enteredPassword.length(); i++) {
                lcd.print("*");
            }

            if (enteredPassword.length() == 4) {
                if (enteredPassword == correctPassword) {
                    digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
                    lcd.clear();
                    lcd.setCursor(0, 0);
                    lcd.print("Mo khoa thanh cong!");
                    delay(2000);
                    lcd.clear();
                    preferences.begin("config", false);
                    preferences.putInt("incorrectAttempts", 0);  // Reset số lần sai khi nhập đúng
                    preferences.end();
                    return 0;  // Reset incorrectAttempts về 0
                } else {
                    lcd.clear();
                    lcd.setCursor(0, 0);
                    lcd.print("Sai ma khoa!");
                    delay(2000);
                    lcd.clear();
                    enteredPassword = "";
                    incorrectAttempts++;
                    lastWrongAttemptTime = currentMillis;

                    // Lưu lại số lần sai vào NVS ngay sau mỗi lần sai
                    preferences.begin("config", false);
                    preferences.putInt("incorrectAttempts", incorrectAttempts); // Lưu lại số lần sai vào NVS
                    preferences.end();

                    // Kiểm tra nếu sai 5 lần liên tiếp
                    if (incorrectAttempts >= 5) {
                        lcd.clear();
                        lcd.setCursor(0, 0);
                        lcd.print("Vo hieu hoa khoa!");
                        Serial.println("Vô hiệu hóa mã khóa");

                        unsigned long buzzerStart = millis();
                        while (millis() - buzzerStart < 180000) { // 3 phút = 180000ms
                            digitalWrite(GPO_CONFIG::BUZZER_PIN, HIGH);
                            delay(1000);  // kêu 1 giây
                            digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);
                            delay(1000);  // nghỉ 1 giây
                        }

                        lcd.clear();
                        return incorrectAttempts;  // Trả về số lần sai
                    }

                    lcd.setCursor(0, 0);
                    lcd.print("Nhap ma khoa");
                }
            }
        }

        // Reset bộ đếm nếu sau 30 phút
        if (incorrectAttempts >= 5 && (currentMillis - lastWrongAttemptTime > wrongAttemptResetDuration)) {
            incorrectAttempts = 0;
            preferences.begin("config", false);
            preferences.putInt("incorrectAttempts", 0); // Reset lại khi đủ 30 phút
            preferences.end();
        }

        delay(50); // tránh chiếm CPU toàn bộ
    }
}
