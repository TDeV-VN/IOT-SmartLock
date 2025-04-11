#include <WiFi.h>
#include <WebServer.h>

WebServer server(80);

void handleRoot() {
  String html = "<html><body>";
  html += "<h1>Connect to WiFi</h1>";
  html += "<form action='/connect' method='POST'>";
  html += "SSID: <input type='text' name='ssid'><br>";
  html += "Password: <input type='password' name='password'><br>";
  html += "<input type='submit' value='Connect'>";
  html += "</form></body></html>";
  server.send(200, "text/html", html);
}

void handleConnectWiFi() {
  String ssid = server.arg("ssid");
  String password = server.arg("password");

  WiFi.begin(ssid.c_str(), password.c_str());

  if (WiFi.waitForConnectResult() == WL_CONNECTED) {
    server.send(200, "text/plain", "Connected to WiFi! IP: " + WiFi.localIP().toString());
  } else {
    server.send(200, "text/plain", "Failed to connect.");
  }
}

void setupWifiServer() {
  WiFi.softAP("SLock", "123456789");
  server.on("/", HTTP_GET, handleRoot);
  server.on("/connect", HTTP_POST, handleConnectWiFi);
  server.begin();
  Serial.println("Web server started at IP: " + WiFi.softAPIP().toString());
}

void handleWifiClient() {
  server.handleClient();
}
