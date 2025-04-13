// firmware_update.h

#ifndef FIRMWARE_UPDATE_H
#define FIRMWARE_UPDATE_H

#include <Arduino.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <Update.h>
#include <ArduinoJson.h>  // Thư viện JSON cần thiết

bool checkAndUpdateFirmware(const String &currentVersion);

#endif // FIRMWARE_UPDATE_H
