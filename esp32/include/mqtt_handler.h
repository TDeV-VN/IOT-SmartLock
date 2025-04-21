#include <PubSubClient.h>
#include <LiquidCrystal_I2C.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <lock_control.h>
#include <Update.h>

void reconnect(String& lockId, LiquidCrystal_I2C &lcd);
void callback(char* topic, byte* payload, unsigned int length, LiquidCrystal_I2C &lcd);
void mqttSetup(LiquidCrystal_I2C &lcd);
void mqttLoop(String lockId, LiquidCrystal_I2C &lcd);
void mqttSend(String topic, String message);
bool checkFirmware(LiquidCrystal_I2C &lcd);
void updateFirmware(LiquidCrystal_I2C &lcd);