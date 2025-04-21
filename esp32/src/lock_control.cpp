#include <Keypad.h>
#include <Preferences.h>  
#include <gpo_config.h>
#include "firebase_handler.h"
#include "lock_control.h"
#include <config.h>

Preferences preferences_lockcontrol;
String enteredPassword = ""; // Mã khóa nhập vào
int incorrectAttempts = 0; // Số lần nhập sai

// Mã khóa đúng
String getPinCodeFromNVS() {
    Preferences preferences;
    preferences.begin("config", true); // Mở namespace "config" ở chế độ chỉ đọc
    String pinCode = preferences.getString("pinCode", "null"); // Lấy mã khóa
    preferences.end();
    return pinCode;
}

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
        if (currentMillis - lastKeypressTime > Config::timeoutDuration) {
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
                    openLock(lcd); // Mở khóa nếu mã đúng
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

                    // Kiểm tra số lần sai liên tiếp
                    if (incorrectAttempts >= Config::maxWrongAttempts) {
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
                        putPinCodeDisable(getLockId(), Config::pinCodeDisableDuration);

                        Serial.println("Vô hiệu hóa mã khóa");

                        unsigned long buzzerStart = millis();
                        while (millis() - buzzerStart < Config::buzzerDuration) { 
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

void openLock(LiquidCrystal_I2C &lcd) {
    digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
    changeLockStatus(getLockId(), false); // cập nhật trạng thái khóa
    // Buzzer kêu khi mở khóa thành công
    digitalWrite(GPO_CONFIG::BUZZER_PIN, HIGH);
    delay(Config::buzzerUnlockDuration);
    digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);
    // lcd
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Da mo khoa!");

    preferences_lockcontrol.begin("config", false);
    // reset thời gian và số lần sai
    preferences_lockcontrol.putInt("incorrectAttempts", 0);
    preferences_lockcontrol.putULong("firstWrongAttemptTime", 0);
    preferences_lockcontrol.end();
    delay(Config::relayDuration - Config::buzzerUnlockDuration); // Giữ relay mở trong thời gian quy định
    digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); // Đóng relay lại
    changeLockStatus(getLockId(), true); // Cập nhật trạng thái khóa

    lcd.clear();
    
    // ghi lịch sử mở khóa vào Firebase
    putOpenHistory(getUuidFromNVS(), getLockId(), "mã khóa", "Ổ khóa");
    // xóa vô hiệu mã khóa ở firebase
    deletePinCodeDisable(getLockId());
}

String getFirmwareVersion() {
    String version = "v1.0.8"; // Phiên bản hiện tại
    return version;
}