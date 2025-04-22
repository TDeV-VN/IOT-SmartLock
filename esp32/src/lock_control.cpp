#include <Keypad.h>
#include <Preferences.h>  
#include <gpo_config.h>
#include "firebase_handler.h"
#include "lock_control.h"
#include <config.h>

Preferences preferences;
String enteredPassword = ""; // Mã khóa nhập vào
int incorrectAttempts = 0; // Số lần nhập sai

// Mã khóa đúng
String getPinCodeFromNVS() {
    preferences.begin("config", true); // Mở namespace "config" ở chế độ chỉ đọc
    String pinCode = preferences.getString("pinCode", "null"); // Lấy mã khóa
    preferences.end();
    return pinCode;
}

static unsigned long lastKeypressTime = 0; // Biến lưu thời gian nhấn phím cuối cùng
void handleLockControl(Keypad &keypad, LiquidCrystal_I2C &lcd) {
    preferences.begin("PinCodeEnable", false);
    incorrectAttempts = preferences.getInt("k", 0);  // Đọc lại số lần sai từ NVS
    Serial.println("Số lần sai: " + String(incorrectAttempts));  // In số lần sai từ NVS
    // lấy thời gian sai đầu tiên từ NVS
    time_t firstWrongAttemptTime = preferences.getULong("f", 0); // Đọc timestamp từ NVS
    preferences.end();

    // //test
    // lcd.clear();
    // lcd.setCursor(0, 0);
    // lcd.print("So lan sai: " + String(incorrectAttempts)); // In số lần sai
    // lcd.setCursor(0, 1);
    // lcd.print("Thoi gian: " + String(firstWrongAttemptTime)); // In thời gian sai đầu tiên
    // delay(5000);  

    // kiểm tra thời gian sai đầu tiên và thời gian hiện tại
    unsigned long currentMillis = millis();
    if (firstWrongAttemptTime != 0 && (time(nullptr) - firstWrongAttemptTime) > Config::wrongAttemptDuration) {
        // Nếu thời gian sai đầu tiên đã quá thời gian quy định thì reset lại số lần sai
        preferences.begin("PinCodeEnable", false);
        preferences.remove("k");
        preferences.remove("f");
        preferences.end();
        incorrectAttempts = 0; // Reset biến toàn cục
    } else if (incorrectAttempts >= Config::maxWrongAttempts) {
        // Nếu đã sai quá số lần quy định thì không cho nhập mã khóa
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Ma khoa da");
        lcd.setCursor(0, 1);
        lcd.print("bi vo hieu hoa!");
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

            if (key == '*') {
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

                    // Lưu lại số lần sai
                    preferences.begin("PinCodeEnable", false);
                    preferences.putInt("k", incorrectAttempts); // Lưu lại số lần sai vào NVS
                    
                    if (incorrectAttempts == 1) {
                        time_t currentTimestamp = time(nullptr); // Lấy timestamp hiện tại
                        preferences.putULong("f", currentTimestamp); // Lưu timestamp vào NVSsai đầu tiên
                    }

                    preferences.end();

                    // Kiểm tra số lần sai liên tiếp
                    if (incorrectAttempts >= Config::maxWrongAttempts) {
                        lcd.clear();
                        lcd.setCursor(0, 0);
                        lcd.print("Vo hieu hoa");
                        lcd.setCursor(0, 1);
                        lcd.print("ma khoa!");

                        // Gửi FCM
                        String topic = "warning_" + getLockId();
                        String title = "Cảnh báo truy cập trái phép!";
                        sendLockNotification(topic, title, "Phương thức mở bằng mã khóa đã bị vô hiệu hóa!");

                        //ghi lịch sử vào Firebase
                        putWarningHistory(getUuidFromNVS(), getLockId(), "Truy cập trái phép");

                        // Ghi vào Firebase để vô hiệu hóa mã khóa trong 30 phút
                        putPinCodeDisable(getLockId(), Config::pinCodeDisableDuration);

                        Serial.println("Vô hiệu hóa mã khóa");
                        digitalWrite(GPO_CONFIG::BUZZER_PIN, HIGH);
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
    preferences.begin("config", true); // true = chỉ đọc
    String uuid = preferences.getString("uuid", ""); // "" là giá trị mặc định nếu chưa có
    preferences.end();
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

    preferences.begin("PinCodeEnable", false);
    preferences.remove("k");
    preferences.remove("f");
    preferences.end();
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
    String version = "v1.1.2"; // Phiên bản hiện tại
    return version;
}

void sendLockNotification(const String& topic, const String& title, const String& message) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[Notification] WiFi not connected!");
        return;
    }
  
    HTTPClient http;
    http.begin("https://iot-smartlock-firmware.onrender.com/send-topic");
    http.addHeader("Content-Type", "application/json");
  
    DynamicJsonDocument doc(256);
    doc["topic"] = topic;
    doc["title"] = title;
    doc["body"] = message;
  
    String payload;
    serializeJson(doc, payload);
  
    int httpCode = http.POST(payload);
    
    if (httpCode > 0) {
        Serial.printf("[Notification] Sent! Code: %d\n", httpCode);
    } else {
        Serial.printf("[Notification] Failed! Error: %s\n", http.errorToString(httpCode).c_str());
    }
  
    http.end();
  }