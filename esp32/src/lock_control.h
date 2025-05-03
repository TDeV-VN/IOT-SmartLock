#ifndef LOCK_CONTROL_H
#define LOCK_CONTROL_H

#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Preferences.h>
#include <HTTPClient.h>  
#include <ArduinoJson.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

extern Preferences preferences;
extern int incorrectAttempts;
extern String enteredPassword;

// Khai báo các biến timeout
extern const unsigned long timeoutDuration;
extern const unsigned long wrongAttemptResetDuration;

extern TaskHandle_t buzzerTaskHandle; // Handle cho task điều khiển buzzer

// Khai báo hàm xử lý mã khóa
void handleLockControl(Keypad &keypad, LiquidCrystal_I2C &lcd, bool isReset);
void openLock(LiquidCrystal_I2C &lcd);
String getUuidFromNVS();
String getLockId();

String getFirmwareVersion();
void sendLockNotification(const String& topic, const String& title, const String& message);
void buzzerTask(void * parameter);

#endif
