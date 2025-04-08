#include <Arduino.h>

struct GPO_CONFIG
{
    static const int RELAY_PIN = 4; // Chân nối relay
    static const int BUZZER_PIN = 2; // Chân nối buzzer

    // LCD 16x2
    static const int RS = 23;
    static const int E = 19;
    static const int D4 = 18;
    static const int D5 = 17;
    static const int D6 = 16;
    static const int D7 = 15;

    // Keypad
    static const byte rows = 4;
    static const byte cols = 4;
    static const char keys[rows][cols];
    static byte rowPins[rows];
    static byte colPins[cols];
};


