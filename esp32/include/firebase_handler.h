#ifndef FIREBASE_HANDLER_H
#define FIREBASE_HANDLER_H

#include <FirebaseESP32.h>

extern FirebaseData fbdo;

void firebaseSetup();
void firebaseLoop(const String& lockId);
void putOpenHistory(const String& uuid, const String& lockId, const String& method, const String& device);
void putWarningHistory(const String& uuid, const String& lockId, const String& message);
void deletePinCodeDisable(const String& lockId);
bool checkPinCodeEnable(const String& lockId);

#endif
