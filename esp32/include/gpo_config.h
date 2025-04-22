#ifndef GPO_CONFIG_H
#define GPO_CONFIG_H

#include <Arduino.h>

struct GPO_CONFIG
{
    static const int RELAY_PIN = 4; // Chân nối relay
    static const int BUZZER_PIN = 23; // Chân nối buzzer

    // Keypad
    static const byte rows = 4;
    static const byte cols = 4;
    static const char keys[rows][cols];
    static byte rowPins[rows];
    static byte colPins[cols];
};

#endif // GPO_CONFIG_H
