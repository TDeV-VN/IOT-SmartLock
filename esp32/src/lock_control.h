#ifndef LOCK_CONTROL_H
#define LOCK_CONTROL_H

#include <Keypad.h>
#include <LiquidCrystal_I2C.h>
#include <Preferences.h>

extern Preferences preferences;
extern int incorrectAttempts;
extern String enteredPassword;

// Khai báo các biến timeout
extern const unsigned long timeoutDuration;
extern const unsigned long wrongAttemptResetDuration;

// Khai báo hàm xử lý mã khóa
void handleLockControl(Keypad &keypad, LiquidCrystal_I2C &lcd);

String getUuidFromNVS();
String getLockId();

#endif
