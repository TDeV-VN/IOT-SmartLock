#include "WebServerHandler.h"
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include "lock_control.h"

WebServer server(80);
extern Preferences preferences;

// Tạo con trỏ toàn cục cho LCD
LiquidCrystal_I2C *lcdGlobal;

void setupAP() {
  WiFi.softAP("Slock_AP", "12345678");
  lcdGlobal->clear();
  lcdGlobal->setCursor(0, 0);
  lcdGlobal->print("Slock_AP");
  lcdGlobal->setCursor(0, 1);
  lcdGlobal->print("12345678");
}

void handleScanWifi() {
  int n = WiFi.scanNetworks();
  String json = "[";
  for (int i = 0; i < n; ++i) {
    json += "\"" + WiFi.SSID(i) + "\"";
    if (i != n - 1) json += ", ";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleGetMac() {
  String mac = getLockId();
  server.send(200, "text/plain", mac);
}

void handleShutdownAP() {
  // Hiển thị lên LCD nếu muốn
  lcdGlobal->clear();
  lcdGlobal->setCursor(0, 0);
  lcdGlobal->print("Off AP...");
  // Ngắt SoftAP
  WiFi.softAPdisconnect(true);
  server.stop();
  delay(1000);
  lcdGlobal->clear();
}


void handleConnectWifi() {
  if (!server.hasArg("ssid") || !server.hasArg("password") || !server.hasArg("uuid")) {
    server.send(400, "text/plain", "Missing ssid or password");
    return;
  }

  String ssid = server.arg("ssid");
  String password = server.arg("password");
  String uuid = server.arg("uuid");

  lcdGlobal->clear();
  lcdGlobal->setCursor(0, 0);
  lcdGlobal->print("Connecting to");
  lcdGlobal->setCursor(0, 1);
  lcdGlobal->print(ssid + "...");
  WiFi.mode(WIFI_AP_STA);
  WiFi.begin(ssid.c_str(), password.c_str());

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    lcdGlobal->clear();
    lcdGlobal->setCursor(0, 0);
    lcdGlobal->print("Connected to");
    lcdGlobal->setCursor(0, 1);
    lcdGlobal->print(ssid + "!");

    preferences.begin("config", false);
    preferences.putString("wifiSSID", ssid);
    preferences.putString("wifiPassword", password);
    preferences.putString("uuid", uuid);
    preferences.end();

    server.send(200, "text/plain", "Connected");
    delay(1000);
  } else {
    lcdGlobal->clear();
    lcdGlobal->setCursor(0, 0);
    lcdGlobal->print("Failed to connect");
    delay(2000);

    server.send(500, "text/plain", "Connection failed");
  }
}

void startServer(LiquidCrystal_I2C &lcd) {
  lcdGlobal = &lcd; // Gán con trỏ toàn cục
  setupAP();

  server.on("/scan-wifi/", HTTP_GET, handleScanWifi);
  server.on("/mac/", HTTP_GET, handleGetMac);
  server.on("/connect-wifi/", HTTP_POST, handleConnectWifi);
  server.on("/shutdown-ap/", HTTP_GET, handleShutdownAP);

  server.begin();
  Serial.println("Web server started");
}