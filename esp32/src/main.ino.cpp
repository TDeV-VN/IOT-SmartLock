# 1 "C:\\Users\\thanh\\AppData\\Local\\Temp\\tmpuwlk_vqx"
#include <Arduino.h>
# 1 "E:/IOT/IOT-SmartLock/esp32/src/main.ino"

#include <Arduino.h>
#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include "firebase_handler.h"
#include <gpo_config.h>
#include "lock_control.h"
#include "WebServerHandler.h"
#include "mqtt_handler.h"
#include <Preferences.h>


extern Preferences preferences;
TaskHandle_t buzzerTaskHandle = NULL;
TaskHandle_t relayTaskHandle = NULL;

#define FIRMWARE_VERSION getFirmwareVersion()
String lockId = getLockId();


void setupWifiServer();
void handleWifiClient();


Keypad keypad = Keypad(makeKeymap(GPO_CONFIG::keys), GPO_CONFIG::rowPins, GPO_CONFIG::colPins, GPO_CONFIG::rows, GPO_CONFIG::cols);


LiquidCrystal_I2C lcd(0x27, 16, 2);

unsigned long lastFirebaseUpdate = 0;
const unsigned long FIREBASE_INTERVAL = 1000;


bool hashKeyHeld = false;
unsigned long hashKeyPressStartTime = 0;
const unsigned long HASH_HOLD_DURATION = 5000;
bool resetTriggered = false;
void setup();
void loop();
void resetLock();
void connectwifi();
#line 41 "E:/IOT/IOT-SmartLock/esp32/src/main.ino"
void setup() {
  Serial.begin(115200);


  lcd.init();
  lcd.backlight();


  pinMode(GPO_CONFIG::RELAY_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::RELAY_PIN, HIGH);

  pinMode(GPO_CONFIG::BUZZER_PIN, OUTPUT);
  digitalWrite(GPO_CONFIG::BUZZER_PIN, LOW);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Firmware " + String(FIRMWARE_VERSION));
  lcd.setCursor(0, 1);
  delay(1000);


  xTaskCreate(
    buzzerTask,
    "BuzzerTask",
    2048,
    NULL,
    1,
    &buzzerTaskHandle
  );


  if (buzzerTaskHandle == NULL) {
    Serial.println("Failed to create Buzzer Task!");
  } else {
    Serial.println("Buzzer Task created successfully.");
  }


  #ifdef WOKWI_SIMULATION
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Wokwi Simulation");
    delay(1000);
    lcd.clear();

    lcd.clear();
    lcd.print("Connecting WiFi...");
    WiFi.begin("Wokwi-GUEST", "", 6);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
    }
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connected to WiFi");
    delay(1000);
    lcd.clear();
  #else
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Physical Device");
    delay(1000);
    lcd.clear();

    connectwifi();




  #endif


  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting for NTP time sync...");
  lcd.setCursor(0, 0);
  lcd.print("Waiting for NTP");


  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
      delay(500);
      Serial.print(".");
      now = time(nullptr);
  }


  firebaseSetup(lcd);


  mqttSetup(lcd);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("San sang");
  lcd.setCursor(0, 1);
  lcd.print("hoat dong!");
  delay(1000);
  lcd.clear();
}

void loop() {

  if (WiFi.status() != WL_CONNECTED) {
    preferences.begin("config", false);
    String ssid = preferences.getString("wifiSSID", "");
    String password = preferences.getString("wifiPassword", "");
    preferences.end();

    WiFi.begin(ssid.c_str(), password.c_str());
  }

  if (WiFi.status() == WL_CONNECTED){
    mqttLoop(lockId, lcd);
  }


  extern WebServer server;
  server.handleClient();



  if (keypad.getKeys()) {
    for (int i = 0; i < LIST_MAX; i++) {
        if (keypad.key[i].stateChanged) {
            char currentKey = keypad.key[i].kchar;
            KeyState currentState = keypad.key[i].kstate;

            if (currentKey == '#') {
                if (currentState == PRESSED) {
                    Serial.println("Key '#' PRESSED");
                    hashKeyHeld = true;
                    hashKeyPressStartTime = millis();
                    resetTriggered = false;

                    lcd.clear();
                    lcd.print("Giu # de reset");
                } else if (currentState == RELEASED) {
                    Serial.println("Key '#' RELEASED");
                    hashKeyHeld = false;
                    hashKeyPressStartTime = 0;
                    if (!resetTriggered) {
                       lcd.clear();
                    }
                }
            } else if (currentKey == '*') {
                 if (currentState == PRESSED) {
                     Serial.println("Key '*' PRESSED");

                     if (hashKeyHeld) {
                         hashKeyHeld = false;
                         hashKeyPressStartTime = 0;
                         lcd.clear();
                     }
                     handleLockControl(keypad, lcd, false);
                 }
            }

        }
    }
}


if (hashKeyHeld && !resetTriggered) {
    unsigned long heldDuration = millis() - hashKeyPressStartTime;

    if (heldDuration >= HASH_HOLD_DURATION) {
        Serial.println("Key '#' held for 5 seconds. Triggering reset...");

        resetTriggered = true;
        hashKeyHeld = false;
        handleLockControl(keypad, lcd, true);
    }
}



  if ((millis() - lastFirebaseUpdate > FIREBASE_INTERVAL) && WiFi.status() == WL_CONNECTED) {
    firebaseLoop(lcd, lockId);
    lastFirebaseUpdate = millis();
  }
}

void resetLock() {
  Serial.println("##### RESET LOCK FUNCTION CALLED! #####");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Resetting lock...");
  delay(2000);
  lcd.clear();


  preferences.begin("config", false);
  preferences.clear();
  preferences.end();
  delay(1000);
  preferences.begin("PinCodeEnable", false);
  preferences.clear();
  preferences.end();
  delay(1000);


  if (WiFi.status() != WL_CONNECTED) {
    if (resetLockDataForAllUsers(lockId)) {
      lcd.setCursor(0, 0);
      lcd.print("Reset lock data");
      lcd.setCursor(0, 1);
      lcd.print("successfully!");
    } else {
      lcd.setCursor(0, 0);
      lcd.print("Reset lock data");
      lcd.setCursor(0, 1);
      lcd.print("failed!");
    }
  }


  ESP.restart();
}

void connectwifi() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to WiFi...");


  preferences.begin("config", false);
  String ssid = preferences.getString("wifiSSID", "");
  String password = preferences.getString("wifiPassword", "");
  preferences.end();


  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting to");
  lcd.setCursor(0, 1);
  lcd.print(ssid + "...");

  WiFi.begin(ssid.c_str(), password.c_str());
  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    retry++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Connected to");
    lcd.setCursor(0, 1);
    lcd.print(ssid + "!");
    delay(1000);
  } else {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Failed to reconnect");
    delay(2000);


    startServer(lcd);
    while (WiFi.status() != WL_CONNECTED) {
      extern WebServer server;
      server.handleClient();
      delay(500);
    }
  }
  lcd.clear();
}