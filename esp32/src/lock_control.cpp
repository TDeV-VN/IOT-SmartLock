#include <Keypad.h>
#include <LiquidCrystal.h>
#include <Preferences.h>  
#include <gpo_config.h>

Preferences preferences;
int incorrectAttempts = 0; // Số lần nhập sai
String enteredPassword = ""; // Mã khóa nhập vào

// Mã khóa mặc định
const String correctPassword = "1111";

// Cấu hình timeout
const unsigned long timeoutDuration = 60000; // 1 phút (60,000 ms)
const unsigned long wrongAttemptResetDuration = 1800000; // 30 phút (1,800,000 ms)

// Khai báo thời gian sai cuối cùng và thời gian nhấn phím cuối cùng
static unsigned long lastWrongAttemptTime = 0; // Biến lưu thời gian của lần thử sai cuối cùng
static unsigned long lastKeypressTime = 0; // Biến lưu thời gian nhấn phím cuối cùng


void handleLockControl(Keypad &keypad, LiquidCrystal &lcd) {
    preferences.begin("config", false);
    incorrectAttempts = preferences.getInt("incorrectAttempts", 0);
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
            return;
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
                return;
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
                    preferences.putInt("incorrectAttempts", 0);
                    preferences.end();
                    return;
                } else {
                    lcd.clear();
                    lcd.setCursor(0, 0);
                    lcd.print("Sai ma khoa!");
                    delay(2000);
                    lcd.clear();
                    enteredPassword = "";
                    incorrectAttempts++;
                    lastWrongAttemptTime = currentMillis;

                    preferences.begin("config", false);
                    preferences.putInt("incorrectAttempts", incorrectAttempts);
                    preferences.end();

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
                        return;
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
            preferences.putInt("incorrectAttempts", 0);
            preferences.end();
        }

        delay(50); // tránh chiếm CPU toàn bộ
    }
}

