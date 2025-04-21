#include <FirebaseESP32.h>
#include <Preferences.h>
#include "firebase_handler.h"
#include "gpo_config.h"
#include <time.h>
#include <config.h>

#define FIREBASE_HOST "https://slock-bb631-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "AIzaSyBUmpTr3r3gfn7erG-KYPMoUXXbseVPOSs"

FirebaseData fbdo;
Preferences preferences_firebase;

bool isUnlocking = false;
String currentPinCode = "";

void firebaseSetup(LiquidCrystal_I2C& lcd) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Dang ket noi");
  lcd.setCursor(0, 1);
  lcd.print("database...");
  delay(2000);

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);

  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); 

  preferences_firebase.begin("config", false);
  currentPinCode = preferences_firebase.getString("pinCode", "");
  Serial.printf("PIN code hiện tại từ NVS: %s\n", currentPinCode.c_str());

  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");

  Serial.println("Firebase đã khởi động!");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Da ket noi");
  lcd.setCursor(0, 1);
  lcd.print("database!");
  delay(2000);
  lcd.clear();
}

void firebaseLoop(const String& lockId) {
  static unsigned long lastRun = 0;
  unsigned long interval = 5000;
  if (millis() - lastRun < interval) return;
  lastRun = millis();

  String basePath = "/lock/" + lockId;

  // theo dõi đồng bộ trạng thái khóa
  if (Firebase.getBool(fbdo, basePath + "/locking_status")) {
    bool locking = fbdo.boolData();
    Serial.printf("[%s] locking_status = %s\n", lockId.c_str(), locking ? "true" : "false");

    if (!locking && !isUnlocking) {
      isUnlocking = true;

      Serial.println("Mở khóa (tắt relay) trong 5s...");
      digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
      delay(Config::relayDuration);
      digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);
      Serial.println("Khóa lại (bật relay). Cập nhật Firebase...");

      if (Firebase.setBool(fbdo, basePath + "/locking_status", true)) {
        Serial.println("Đã cập nhật locking_status = true");
      } else {
        Serial.printf("Lỗi khi cập nhật Firebase: %s\n", fbdo.errorReason().c_str());
      }

      isUnlocking = false;
    }
  } else {
    Serial.printf("Lỗi khi đọc locking_status: %s\n", fbdo.errorReason().c_str());
  }

  // theo dõi đồng bộ pin code
  if (Firebase.getString(fbdo, basePath + "/pin_code")) {
    String newPin = fbdo.stringData();
    if (newPin != currentPinCode) {
      Serial.printf("Phát hiện PIN code mới từ Firebase: %s\n", newPin.c_str());
      preferences_firebase.putString("pinCode", newPin);
      currentPinCode = newPin;
      Serial.println("Đã cập nhật pinCode vào NVS.");
    }
  } else {
    Serial.printf("Lỗi khi đọc pin_code: %s\n", fbdo.errorReason().c_str());
  }
}

void putOpenHistory(const String& uuid, const String& lockId, const String& method, const String& device) {
  String historyPath = "/lock/" + lockId + "/open_history";
  String notiPath = "/account/" + uuid + "/lock";
  unsigned long timestamp = time(nullptr);

  FirebaseJson historyJson;
  historyJson.set("device", device);
  historyJson.set("method", method);
  historyJson.set("time", String(timestamp));

  if (Firebase.pushJSON(fbdo, historyPath, historyJson)) {
    Serial.println("Đã ghi open_history.");
  } else {
    Serial.printf("Lỗi ghi open_history: %s\n", fbdo.errorReason().c_str());
  }

  FirebaseJson notiJson;
  notiJson.set("message", "Mở khóa");
  notiJson.set("time", String(timestamp));

  for (int i = 0; ; i++) {
    String itemPath = notiPath + "/" + String(i);
    if (!Firebase.getString(fbdo, itemPath + "/id")) break;
    if (fbdo.stringData() == lockId) {
      if (Firebase.setJSON(fbdo, itemPath + "/latest_notification", notiJson)) {
        Serial.println("Đã cập nhật latest_notification.");
      } else {
        Serial.printf("Lỗi khi cập nhật notification: %s\n", fbdo.errorReason().c_str());
      }
      break;
    }
  }
}

void putWarningHistory(const String& uuid, const String& lockId, const String& message) {
  String warningPath = "/lock/" + lockId + "/warning_history";
  String notiPath = "/account/" + uuid + "/lock";
  unsigned long timestamp = time(nullptr);

  FirebaseJson warningJson;
  warningJson.set("message", message);
  warningJson.set("time", String(timestamp));

  if (Firebase.pushJSON(fbdo, warningPath, warningJson)) {
    Serial.println("Đã ghi warning_history.");
  } else {
    Serial.printf("Lỗi ghi warning_history: %s\n", fbdo.errorReason().c_str());
  }

  FirebaseJson notiJson;
  notiJson.set("message", message);
  notiJson.set("time", String(timestamp));
  for (int i = 0; ; i++) {
    String itemPath = notiPath + "/" + String(i);
    if (!Firebase.getString(fbdo, itemPath + "/id")) break;
    if (fbdo.stringData() == lockId) {
      if (Firebase.setJSON(fbdo, itemPath + "/latest_notification", notiJson)) {
        Serial.println("Đã cập nhật latest_notification.");
      } else {
        Serial.printf("Lỗi khi cập nhật notification: %s\n", fbdo.errorReason().c_str());
      }
      break;
    }
  }
}

void deletePinCodeDisable(const String& lockId) {
  String path = "/lock/" + lockId + "/pin_code_disable";
  if (Firebase.deleteNode(fbdo, path)) {
    Serial.println("Đã xóa pin_code_disable.");
  } else {
    Serial.printf("Lỗi khi xóa pin_code_disable: %s\n", fbdo.errorReason().c_str());
  }
}

void putPinCodeDisable(const String& lockId, unsigned long duration) {
  String path = "/lock/" + lockId + "/pin_code_disable";
  unsigned long disableUntil = time(nullptr) + duration;

  FirebaseJson disableJson;
  disableJson.set("expiration_time", String(disableUntil));
  disableJson.set("creation_time", String(time(nullptr)));

  if (Firebase.setJSON(fbdo, path, disableJson)) {
    Serial.println("Đã ghi pin_code_disable.");
  } else {
    Serial.printf("Lỗi ghi pin_code_disable: %s\n", fbdo.errorReason().c_str());
  }
}

bool checkPinCodeEnable(const String& lockId) {
  String path = "/lock/" + lockId + "/pin_code_disable";

  // 1) Đọc dữ liệu tại path vào fbdo
  if (!Firebase.RTDB.getJSON(&fbdo, path)) {
    Serial.printf("Lỗi khi đọc pin_code_disable: %s\n", fbdo.errorReason().c_str());
    return true;
  }

  // 2) Lấy đối tượng JSON từ fbdo
  FirebaseJson &json = fbdo.jsonObject();
  FirebaseJsonData result;

  // 3) Lấy trường "expiration_time"
  if (!json.get(result, "expiration_time")) {
    Serial.println("Không tìm thấy trường expiration_time trong JSON.");
    return true;
  }

  // 4) Chuyển thành timestamp và so sánh
  unsigned long expirationTime = result.to<uint32_t>();
  unsigned long currentTime = time(nullptr);

  Serial.printf("Now = %lu, Expiration = %lu\n", currentTime, expirationTime);
  if (currentTime > expirationTime) {
    // xóa pin_code_disable nếu đã hết thời gian
    deletePinCodeDisable(lockId);
    return true; // Đã hết thời gian vô hiệu hóa mã khóa
  }

  return false;
}

