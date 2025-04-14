#include <FirebaseESP32.h>
#include <preferences.h>
#include "gpo_config.h"

#define FIREBASE_HOST "https://slock-bb631-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "AIzaSyBUmpTr3r3gfn7erG-KYPMoUXXbseVPOSs"

FirebaseData fbdo;
Preferences preferences_firebase;

bool isUnlocking = false;
String currentPinCode = "";

void firebaseSetup() {
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);

  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); 

  preferences_firebase.begin("config", false);
  currentPinCode = preferences_firebase.getString("pinCode", "");
  Serial.printf("PIN code hiện tại từ NVS: %s\n", currentPinCode.c_str());

  Serial.println("Firebase đã khởi động!");
}

void firebaseLoop(const String& lockId) {
  static unsigned long lastRun = 0;
  unsigned long interval = 5000; // 5 giây
  if (millis() - lastRun < interval) return;
  lastRun = millis();

  String basePath = "/lock/" + lockId;

  // 1. Kiểm tra locking_status
  if (Firebase.getBool(fbdo, basePath + "/locking_status")) {
    bool locking = fbdo.boolData();
    Serial.printf("[%s] locking_status = %s\n", lockId.c_str(), locking ? "true" : "false");

    if (!locking && !isUnlocking) {
      isUnlocking = true;

      // Mở khóa
      Serial.println("Mở khóa (tắt relay) trong 5s...");
      digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
      delay(5000); // Có thể dùng millis nếu muốn non-blocking hoàn toàn
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

  // 2. Kiểm tra và cập nhật pin_code nếu thay đổi
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
