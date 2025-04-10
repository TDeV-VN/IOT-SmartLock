#include <WiFi.h>
#include <FirebaseESP32.h>
#include "gpo_config.h"

#define FIREBASE_HOST "https://slock-bb631-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "AIzaSyBUmpTr3r3gfn7erG-KYPMoUXXbseVPOSs"

FirebaseData fbdo;

bool isUnlocking = false;

void firebaseSetup() {
  WiFi.begin("Wokwi-GUEST", "", 6);
  Serial.print("Đang kết nối WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n✅ WiFi đã kết nối!");

  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);

  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH); 

  Serial.println("✅ Firebase đã khởi động!");
}

void firebaseLoop() {
  if (Firebase.getBool(fbdo, "/lock/lock_id1/locking_status")) {
    bool locking = fbdo.boolData();
    Serial.printf("🔄 Trạng thái locking_status = %s\n", locking ? "true" : "false");

    if (!locking && !isUnlocking) {
      isUnlocking = true;

      // Mở khóa (relay off)
      Serial.println("🔓 Mở khóa (tắt relay) trong 5s...");
      digitalWrite(GPO_CONFIG::RELAY_PIN, LOW);
      delay(5000);

      // Đóng khóa (relay on)
      Serial.println("🔒 Khóa lại (bật relay). Cập nhật Firebase...");
      digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);

      // Cập nhật lại lên Firebase
      if (Firebase.setBool(fbdo, "/lock/lock_id1/locking_status", true)) {
        Serial.println("Đã cập nhật locking_status = true");
      } else {
        Serial.println("❌ Lỗi khi cập nhật Firebase");
      }

      isUnlocking = false;
    }
  } else {
    Serial.printf("❌ Lỗi khi đọc locking_status: %s\n", fbdo.errorReason().c_str());
  }

  delay(5000); // Đợi 5s rồi lặp lại
}
