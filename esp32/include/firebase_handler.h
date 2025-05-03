#ifndef FIREBASE_HANDLER_H
#define FIREBASE_HANDLER_H

#include <FirebaseESP32.h>
#include <LiquidCrystal_I2C.h>
#include <lock_control.h>
#include <FirebaseJson.h>
#include <Preferences.h>
#include "gpo_config.h"
#include <time.h>
#include <config.h>

extern FirebaseData fbdo;

void firebaseSetup(LiquidCrystal_I2C& lcd);
void firebaseLoop(LiquidCrystal_I2C& lcd, const String& lockId);
void putOpenHistory(const String& uuid, const String& lockId, const String& method, const String& device);
void putWarningHistory(const String& uuid, const String& lockId, const String& message);
void deletePinCodeDisable(const String& lockId);
bool checkPinCodeEnable(const String& lockId);
void putPinCodeDisable(const String& lockId, unsigned long duration);
void changeLockStatus(const String& lockId, bool status);
bool resetLockDataForAllUsers(const String& lockId);

#endif
