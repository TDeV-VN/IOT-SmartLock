#include "firebase_handler.h"

#define FIREBASE_HOST "https://slock-bb631-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "AIzaSyBUmpTr3r3gfn7erG-KYPMoUXXbseVPOSs"

FirebaseData fbdo;
extern Preferences preferences;

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

  preferences.begin("config", false);
  currentPinCode = preferences.getString("pinCode", "");
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

void firebaseLoop(LiquidCrystal_I2C& lcd, const String& lockId) {
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
      openLock(lcd); // mở khóa
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
      preferences.putString("pinCode", newPin);
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

void changeLockStatus(const String& lockId, bool status) {
  String path = "/lock/" + lockId + "/locking_status";
  if (Firebase.setBool(fbdo, path, status)) {
    Serial.printf("Đã cập nhật trạng thái khóa: %s\n", status ? "true" : "false");
  } else {
    Serial.printf("Lỗi khi cập nhật trạng thái khóa: %s\n", fbdo.errorReason().c_str());
  }
}

bool resetLockDataForAllUsers(const String& lockId) {
  Serial.printf("!!! WARNING: Attempting global reset for lock %s from ESP32 (Two-Pass + Separate FBDO) !!!\n", lockId.c_str());

  bool overallSuccess = true;
  FirebaseJson* accountJsonPtr = nullptr;
  std::vector<String> pathsToDelete;

  // --- Bước 1: Đọc toàn bộ node /account bằng fbdo chính ---
  Serial.println("RESET_ALL_SEP: Pass 1 - Reading /account node...");
  fbdo.setResponseSize(2048);
  if (!Firebase.RTDB.getJSON(&fbdo, "/account")) { // Dùng fbdo chính
      Serial.printf("RESET_ALL_SEP: CRITICAL ERROR - Failed to read /account node: %s\n", fbdo.errorReason().c_str());
      fbdo.setResponseSize(1024);
      return false;
  }
  fbdo.setResponseSize(1024);

  if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_json) {
      accountJsonPtr = fbdo.jsonObjectPtr();
      if (!accountJsonPtr) {
           Serial.println("RESET_ALL_SEP: CRITICAL ERROR - Failed to get JSON object pointer from FirebaseData.");
           return false;
      }

      // --- Bước 2: Lượt 1 - Tìm và Thu thập đường dẫn ---
      Serial.println("RESET_ALL_SEP: Pass 1 - Processing users to find nodes to delete...");
      size_t userCount = accountJsonPtr->iteratorBegin();
      Serial.printf("RESET_ALL_SEP: Found %d potential user entries.\n", userCount);

      String currentUserId = "";
      String value = "";
      int type = 0;

      for (size_t i = 0; i < userCount; i++) {
          accountJsonPtr->iteratorGet(i, type, currentUserId, value);

          if (type == FirebaseJson::JSON_OBJECT && currentUserId.length() > 0) {
              Serial.printf("RESET_ALL_SEP: Pass 1 ---- Processing user: %s ----\n", currentUserId.c_str());
              String userLocksBasePath = "/account/" + currentUserId + "/lock";

              // --- TẠO FirebaseData riêng cho việc đọc list lock ---
              FirebaseData fbdoUserLock;
              // --------------------------------------------------

              Serial.printf("RESET_ALL_SEP: Pass 1 - Attempting to read: %s\n", userLocksBasePath.c_str());
              // --- Đọc danh sách khóa của user bằng fbdoUserLock ---
              if (Firebase.get(fbdoUserLock, userLocksBasePath)) {
              // ----------------------------------------------------
                  Serial.printf("RESET_ALL_SEP: Pass 1 - Read successful for %s. Data type: %s\n", currentUserId.c_str(), fbdoUserLock.dataType().c_str());

                  if (fbdoUserLock.dataType() == "array") { // <<<=== Kiểm tra kiểu dữ liệu trên fbdoUserLock
                      FirebaseJsonArray* currentArray = fbdoUserLock.jsonArrayPtr(); // <<<=== Lấy từ fbdoUserLock
                      if (currentArray) {
                          size_t len = currentArray->size();
                          int foundIndex = -1;
                          Serial.printf("RESET_ALL_SEP: Pass 1 - User %s has lock array (size %d). Searching...\n", currentUserId.c_str(), len);
                          // Tìm index
                          for (size_t j = 0; j < len; j++) {
                              FirebaseJsonData itemData;
                              if (currentArray->get(itemData, j) && itemData.type == "object") {
                                  FirebaseJson itemJson;
                                  if (itemJson.setJsonData(itemData.stringValue)) {
                                      FirebaseJsonData idResult;
                                      if (itemJson.get(idResult, "id") && idResult.success && idResult.type == "string") {
                                          if (idResult.stringValue == lockId) {
                                              foundIndex = j;
                                              Serial.printf("RESET_ALL_SEP: Pass 1 - Found match at index %d for user %s.\n", foundIndex, currentUserId.c_str());
                                              itemJson.clear();
                                              break;
                                          }
                                      }
                                      itemJson.clear();
                                  }
                              }
                          } // end loop j (tìm index)

                          if (foundIndex != -1) {
                              String nodeToDeletePath = userLocksBasePath + "/" + String(foundIndex);
                              Serial.printf("RESET_ALL_SEP: Pass 1 - Storing path: %s\n", nodeToDeletePath.c_str());
                              pathsToDelete.push_back(nodeToDeletePath); // Lưu đường dẫn
                          } else {
                              Serial.printf("RESET_ALL_SEP: Pass 1 - Lock %s not found in user %s list.\n", lockId.c_str(), currentUserId.c_str());
                          }
                      } else { /* Log lỗi lấy array ptr */ overallSuccess = false; }
                  } else if (fbdoUserLock.dataTypeEnum() != fb_esp_rtdb_data_type_null) { /* Log warning */ }
                    else { Serial.printf("RESET_ALL_SEP: Pass 1 - Lock list for user %s is null.\n", currentUserId.c_str()); }
              } else {
                   // Lỗi khi đọc /account/{userId}/lock
                   Serial.printf("RESET_ALL_SEP: Pass 1 - FAILED to read %s for user %s: %s\n", userLocksBasePath.c_str(), currentUserId.c_str(), fbdoUserLock.errorReason().c_str()); // <<<=== Lấy lỗi từ fbdoUserLock
              }
              // fbdoUserLock sẽ tự được giải phóng khi ra khỏi scope
          } else {
               Serial.printf("RESET_ALL_SEP: Skipping entry %d - Not a valid user object (type: %d, key: '%s')\n", i, type, currentUserId.c_str());
          }
          Serial.printf("RESET_ALL_SEP: Pass 1 ---- Finished processing user: %s ----\n\n", currentUserId.c_str());
      } // end loop i (users)
      accountJsonPtr->iteratorEnd(); // Kết thúc duyệt qua các user bằng iterator của fbdo chính
  } else if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_null) { /* Log /account rỗng */ }
    else { /* Log lỗi đọc /account */ return false; }

  // --- Bước 3: Lượt 2 - Thực hiện xóa các đường dẫn đã thu thập (dùng fbdo chính) ---
  Serial.printf("RESET_ALL_SEP: Pass 2 - Deleting %d collected paths...\n", pathsToDelete.size());
  for (const String& path : pathsToDelete) {
      Serial.printf("RESET_ALL_SEP: Pass 2 - Deleting node: %s\n", path.c_str());
      if (!Firebase.deleteNode(fbdo, path)) { // <<=== Dùng fbdo chính để xóa
          Serial.printf("RESET_ALL_SEP: Pass 2 - ERROR deleting node %s: %s\n", path.c_str(), fbdo.errorReason().c_str());
          overallSuccess = false;
      } else {
           Serial.printf("RESET_ALL_SEP: Pass 2 - Successfully deleted node %s.\n", path.c_str());
      }
  }
  pathsToDelete.clear();

  // --- Bước 4: Xóa node dữ liệu chính của khóa (/lock/{lockId}) (dùng fbdo chính) ---
  // ... (Phần này giữ nguyên) ...
   bool lockDataDeleteSuccess = false;
   String lockDataPath = "/lock/" + lockId;
   Serial.printf("RESET_ALL_SEP: Final Step - Deleting main lock data at %s\n", lockDataPath.c_str());
   if (Firebase.deleteNode(fbdo, lockDataPath)) { /* ... */ lockDataDeleteSuccess = true; } else { /* ... */ }

  // --- Kết quả cuối cùng ---
  bool finalResult = overallSuccess && lockDataDeleteSuccess;
  Serial.printf("RESET_ALL_SEP: Overall global reset status for lock %s: %s\n", lockId.c_str(), finalResult ? "REPORTED SUCCESS (check logs)" : "REPORTED FAILURE");
  return finalResult;
}