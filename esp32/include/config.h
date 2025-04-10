#include <Arduino.h>

struct Config {
    String wifiSSID;
    String wifiPassword;

    // Firebase
    String firebaseApiKey;
    String databaseUrl;
    String userEmail;
    String userPassword;

    // Access point
    String apSSID;
    String apPassword;
};