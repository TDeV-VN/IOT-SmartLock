#include <mqtt_handler.h>

Preferences preferences_mqtt;

bool isMqttFirstTime = true; // Biến để kiểm tra lần đầu tiên khởi động MQTT

// MQTT broker
const char* mqtt_server = "b51a9ea272b54ffe828ac0fd37e4b087.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "esp32_client";
const char* mqtt_pass = "12345678Tt";

WiFiClientSecure espSecureClient;
PubSubClient client(espSecureClient);

void reconnect(String& lockId, LiquidCrystal_I2C &lcd) {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT...");
    // lần đầu thì hiện thông báo lên LCD
    if (isMqttFirstTime) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Connecting");
      lcd.setCursor(0, 1);
      lcd.print("to MQTT...");
    }

    if (client.connect("ESP32Client", mqtt_user, mqtt_pass)) {
      Serial.println("Connected!");
      String topic = "esp32/" + lockId;
      client.subscribe(topic.c_str());
      if (isMqttFirstTime) {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Connected to");
        lcd.setCursor(0, 1);
        lcd.print("MQTT!");
        delay(1000);
        lcd.clear();
        isMqttFirstTime = false; // Đặt biến thành false sau khi kết nối thành công lần đầu
      }
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      delay(5000);
    }
  }
}

void callback(char* topic, byte* payload, unsigned int length, LiquidCrystal_I2C &lcd) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  for (int i = 0; i < length; i++) {
    Serial.print((char) payload[i]);
  }
  Serial.println();

  String message = String((char*)payload).substring(0, length);
  // xửa lý yêu cầu check firmware
  if (message == "CheckFirmware") {
    checkFirmware(lcd);
  } else if (message == "UpdateFirmware") { // xử lý yêu cầu update firmware
    updateFirmware(lcd);
  }
  
}

void mqttSetup(LiquidCrystal_I2C &lcd) {
    espSecureClient.setInsecure();       // bỏ kiểm tra chứng chỉ (dev)
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback([&lcd](char* topic, byte* payload, unsigned int length) {
        callback(topic, payload, length, lcd);
    });
  }

void mqttLoop(String lockId, LiquidCrystal_I2C &lcd) {
  if (!client.connected()) {
    reconnect(lockId, lcd);
  }
  client.loop();
}

void mqttSend(String topic, String message) {
    if (client.connected()) {
        client.publish(topic.c_str(), message.c_str(), false);
        // Xóa retained message cũ tại topic
        client.publish(topic.c_str(), nullptr, 0, true);
        Serial.println("Published: " + message + " to topic: " + topic);
    } else {
        Serial.println("MQTT client not connected. Cannot publish message.");
    }
}

bool checkFirmware(LiquidCrystal_I2C &lcd) {
    HTTPClient http;
    const String infoUrl = "https://raw.githubusercontent.com/TDeV-VN/IOT-SmartLock-Firmware/firmware/latest.json";
  
    // Gửi yêu cầu HTTP GET để lấy thông tin firmware mới
    http.begin(infoUrl);
    int httpCode = http.GET();
  
    if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      Serial.println("Received data: " + payload);
  
      DynamicJsonDocument doc(1024);
      DeserializationError error = deserializeJson(doc, payload);
      if (error) {
        http.end();
        return false;
      }
  
      String latestVersion = doc["version"];
      String firmwareDownloadUrl = doc["url"];

      // Gửi kết quả lại
      if (client.connected()) {
        StaticJsonDocument<256> doc;
        doc["latest"] = latestVersion;
        doc["current"] = getFirmwareVersion();
        char buffer[256];
        size_t len = serializeJson(doc, buffer);
        String topic = "esp32/" + getLockId() + "/response";
        delay(1000); //quan trọng
        client.publish(topic.c_str(), (const uint8_t*)buffer, len, false);
        // Xóa retained message cũ tại topic
        client.publish(topic.c_str(), nullptr, 0, true);
      }
    }
  
    http.end();
    return false;
}


void updateFirmware(LiquidCrystal_I2C &lcd) {
  const String infoUrl = "https://raw.githubusercontent.com/TDeV-VN/IOT-SmartLock-Firmware/firmware/latest.json";
  HTTPClient http;
  bool isUpdate = false;

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Cap nhat");
  lcd.setCursor(0, 1);
  lcd.print("firmware...");

  // Gửi yêu cầu HTTP GET để lấy thông tin firmware mới
  http.begin(infoUrl);
  int httpCode = http.GET();
  if (httpCode == HTTP_CODE_OK) {
      String payload = http.getString();
      DynamicJsonDocument doc(1024);
      deserializeJson(doc, payload);

      http.begin(doc["url"]);
      int firmwareCode = http.GET();
  
      if (firmwareCode == HTTP_CODE_OK) {
          WiFiClient *client = http.getStreamPtr();
          int contentLength = http.getSize();
  
          if (Update.begin(contentLength)) {
              size_t written = Update.writeStream(*client);
              if (written == contentLength) {
                  if (Update.end(true)) {
                      isUpdate = true;
                  }
              }
          }
      }

  }

  

  http.end();

  if (!isUpdate) {
      // Gửi kết quả lại
      if (client.connected()) {
          StaticJsonDocument<256> doc;
          doc["updateFirmware"] = "err";
          char buffer[256];
          size_t len = serializeJson(doc, buffer);
          String topic = "esp32/" + getLockId() + "/response";
          client.publish(topic.c_str(), (const uint8_t*)buffer, len, false);
          // Xóa retained message cũ tại topic
          client.publish(topic.c_str(), nullptr, 0, true);
      }
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Cap nhat");
      lcd.setCursor(0, 1);
      lcd.print("that bai!");
      delay(1000);
      lcd.clear();
  } else {
      // Gửi kết quả lại
      if (client.connected()) {
          StaticJsonDocument<256> doc;
          doc["updateFirmware"] = "success";
          char buffer[256];
          size_t len = serializeJson(doc, buffer);
          String topic = "esp32/" + getLockId() + "/response";
          client.publish(topic.c_str(), (const uint8_t*)buffer, len, false);
          // Xóa retained message cũ tại topic
          client.publish(topic.c_str(), nullptr, 0, true);

          // Đảm bảo MQTT đã gửi trước khi restart
          delay(1000); // Đợi một thời gian ngắn trước khi restart
          client.loop(); // Xử lý MQTT loop để đảm bảo gửi thông điệp
      } else {
          Serial.println("MQTT client not connected. Cannot publish message.");
          client.loop(); // Xử lý MQTT loop để đảm bảo gửi thông điệp
      }
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Cap nhat");
      lcd.setCursor(0, 1);
      lcd.print("thanh cong!");
      delay(1000);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Khoi dong lai...");
      ESP.restart(); //  Khởi động lại thiết bị
  }
}

