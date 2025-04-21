#include <Keypad.h>
#include <Preferences.h>  
#include <gpo_config.h>
#include "firebase_handler.h"
#include "lock_control.h"

Preferences preferences_lockcontrol;
// int incorrectAttempts; // Số lần nhập sai
String enteredPassword = ""; // Mã khóa nhập vào
int incorrectAttempts = 0; // Số lần nhập sai

// Mã khóa đúng
String getPinCodeFromNVS() {
    Preferences preferences;
    preferences.begin("config", true); // Mở namespace "config" ở chế độ chỉ đọc
    String pinCode = preferences.getString("pinCode", "null"); // Lấy mã khóa, mặc định là "1234" nếu không tồn tại
    preferences.end();
    return pinCode;
}

// Cấu hình timeout
const unsigned long timeoutDuration = 60000; // 1 phút (60,000 ms)
const unsigned long wrongAttemptResetDuration = 1800000; // 30 phút (1,800,000 ms)

// Khai báo thời gian sai cuối cùng và thời gian nhấn phím cuối cùng
static unsigned long firstWrongAttemptTime = 0; // Biến lưu thời gian của lần thử sai đầu tiên
static unsigned long lastKeypressTime = 0; // Biến lưu thời gian nhấn phím cuối cùng
void handleLockControl(Keypad &keypad, LiquidCrystal_I2C &lcd) {
    preferences_lockcontrol.begin("config", false);
    incorrectAttempts = preferences_lockcontrol.getInt("incorrectAttempts", incorrectAttempts);  // Đọc lại số lần sai từ NVS
    Serial.println("Số lần sai: " + String(incorrectAttempts));  // In số lần sai từ NVS
    // lấy thời gian sai đầu tiên từ NVS
    firstWrongAttemptTime = preferences_lockcontrol.getULong("firstWrongAttemptTime", 0); // Đọc thời gian sai đầu tiên từ NVS
    preferences_lockcontrol.end();

    // nếu dữ firebase đã bị vô hiệu hóa mã khóa thì không cho nhập mã khóa
    if (checkPinCodeEnable(getLockId()) == false) {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Ma khoa da");
        lcd.setCursor(0, 1);
        lcd.print("vo hieu hoa!");
        delay(2000);
        lcd.clear();
        return;
    }   

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

                enteredPassword = "";
                return;
            }

            enteredPassword += key;

            lcd.setCursor(0, 1);
            for (int i = 0; i < enteredPassword.length(); i++) {
                lcd.print("*");
            }

            if (enteredPassword.length() == 4) {
                if (enteredPassword == getPinCodeFromNVS()) {
                    digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
                    lcd.clear();
                    lcd.setCursor(0, 0);
                    lcd.print("Da mo khoa!");
                    delay(2000);
                    lcd.clear();
                    preferences_lockcontrol.begin("config", false);
                    preferences_lockcontrol.putInt("incorrectAttempts", 0);  // Reset số lần sai khi nhập đúng
                    //cập nhật thời gian lần sai đầu tiên thành 0
                    preferences_lockcontrol.putULong("firstWrongAttemptTime", 0);
                    preferences_lockcontrol.end();
                    delay(3000); // Giữ relay mở trong 5 giây
                    digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // Đóng relay lại
                    // ghi lịch sử mở khóa vào Firebase
                    putOpenHistory(getUuidFromNVS(), getLockId(), "mã khóa", "Ổ khóa");
                

                    return;
                } else {
                    lcd.clear();
                    lcd.setCursor(0, 0);
                    lcd.print("Sai ma khoa!");
                    delay(2000);
                    lcd.clear();
                    enteredPassword = "";
                    incorrectAttempts++;

                    // Lưu lại số lần sai và lần sai cuối vào NVS ngay sau mỗi lần sai
                    preferences_lockcontrol.begin("config", false);
                    preferences_lockcontrol.putInt("incorrectAttempts", incorrectAttempts); // Lưu lại số lần sai vào NVS
                    
                    if (incorrectAttempts == 1) {
                        firstWrongAttemptTime = currentMillis; // Lưu thời gian sai đầu tiên
                        preferences_lockcontrol.putULong("firstWrongAttemptTime", firstWrongAttemptTime); // Lưu thời gian sai đầu tiên vào NVS
                    }

                    preferences_lockcontrol.end();

                    // Kiểm tra nếu sai 5 lần liên tiếp
                    if (incorrectAttempts >= 5) {
                        lcd.clear();
                        lcd.setCursor(0, 0);
                        lcd.print("Vo hieu hoa");
                        lcd.setCursor(0, 1);
                        lcd.print("ma khoa!");

                        //ghi lịch sử vào Firebase
                        putWarningHistory(getUuidFromNVS(), getLockId(), "Truy cập trái phép");

                        // reset số lần sai và thời gian sai đầu tiên trong nvs
                        preferences_lockcontrol.begin("config", false);
                        preferences_lockcontrol.putInt("incorrectAttempts", 0); // Reset số lần sai
                        preferences_lockcontrol.putULong("firstWrongAttemptTime", 0); // Reset thời gian sai đầu tiên
                        preferences_lockcontrol.end();

                        // Ghi vào Firebase để vô hiệu hóa mã khóa trong 30 phút
                        putPinCodeDisable(getUuidFromNVS(), 1800); // 30 phút = 1800 giây

                        Serial.println("Vô hiệu hóa mã khóa");

                        unsigned long buzzerStart = millis();
                        while (millis() - buzzerStart < 180000) { // 3 phút = 180000ms
                            digitalWrite(GPO_CONFIG::BUZZER_PIN, HIGH);
                            delay(1000);  // kêu 1 giây
                            digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);
                            delay(1000);  // nghỉ 1 giây
                        }

                        lcd.clear();
                        return; // Thoát khỏi vòng lặp sau khi đã thông báo
                    }

                    lcd.setCursor(0, 0);
                    lcd.print("Nhap ma khoa");
                }
            }
        }

        delay(50); // tránh chiếm CPU toàn bộ
    }
}

String getUuidFromNVS() {
    Preferences preferences3;
    preferences3.begin("config", true); // true = chỉ đọc
    String uuid = preferences3.getString("uuid", ""); // "" là giá trị mặc định nếu chưa có
    preferences3.end();
    return uuid;
}

String getLockId() {
    // lấy mac và bỏ đi dấu ":"
    String mac = WiFi.macAddress();
    mac.replace(":", "");
    return mac;
}
