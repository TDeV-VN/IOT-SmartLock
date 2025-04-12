#include "wifi_connection.h"  // Bao gồm tệp header

WebServer server(80);  

void handleScanWifi() {
  int n = WiFi.scanNetworks();  // Quét các mạng Wi-Fi có sẵn
  String response = "[";
  for (int i = 0; i < n; i++) {
    response += "{\"ssid\":\"" + WiFi.SSID(i) + "\", \"rssi\":" + WiFi.RSSI(i) + "},";
  }
  if (n > 0) {
    response.remove(response.length() - 1);  // Xóa dấu ',' cuối cùng
  }
  response += "]";
  
  server.send(200, "application/json", response);  // Trả về danh sách Wi-Fi dưới dạng JSON
}
void handleConnectWifi() {
  String ssid = server.arg("ssid");
  String password = server.arg("password");

  // Kiểm tra nếu không có SSID hoặc mật khẩu
  if (!server.hasArg("ssid") || !server.hasArg("password")) {
    server.send(400, "text/plain", "Missing SSID or Password");
    return;
  }

  // Hiển thị SSID và mật khẩu nhận được từ client
  Serial.println("SSID: " + ssid);
  Serial.println("Password: " + password);

  WiFi.begin(ssid.c_str(), password.c_str());  // Kết nối WiFi

  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED && attempt < 10) {  // Thử kết nối trong 10 lần
    delay(1000);
    Serial.print(".");
    attempt++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    // Kết nối WiFi thành công
    // Lưu SSID và mật khẩu vào NVS
    preferences.begin("config", false);
    preferences.putString("wifiSSID", ssid);
    preferences.putString("wifiPassword", password);
    preferences.end();

    // Tắt AP và WebServer sau khi kết nối thành công
    WiFi.softAPdisconnect(true);  // Tắt AP

    // Trả về kết quả thành công
    server.send(200, "text/plain", "Wifi connected");

    // Có thể khởi động lại WebServer nếu cần, ví dụ:
    // server.begin();  // Khởi động lại WebServer (nếu cần sau khi chuyển sang Station Mode)
  } else {
    // Kết nối WiFi thất bại
    Serial.println("WiFi connection failed");
    server.send(500, "text/plain", "Wifi connect failed");
  }
}



void handleMac() {
  String macAddress = WiFi.macAddress();
  server.send(200, "text/plain", macAddress);  // Trả về MAC address
}

void handleCheckStatus() {
  if (WiFi.status() == WL_CONNECTED) {
    server.send(200, "text/plain", "Connected to WiFi!");
  } else {
    server.send(500, "text/plain", "Not connected to WiFi");
  }
}

void startServer() {
  WiFi.softAP("SLock", "12345678");  // Tạo điểm truy cập Wi-Fi với tên "SLock_AP"
  Serial.println("AP started with IP: " + WiFi.softAPIP().toString());

  server.on("/scan-wifi/", HTTP_GET, handleScanWifi);  // Quét Wi-Fi
  server.on("/connect-wifi/", HTTP_POST, handleConnectWifi);  // Kết nối Wi-Fi
  server.on("/mac/", HTTP_GET, handleMac);  // Lấy MAC address
  server.on("/check-status", HTTP_GET, handleCheckStatus);  // Kiểm tra trạng thái kết nối

  server.begin();  // Khởi động WebServer
  Serial.println("Web server started.");
}

void handleWifiClient() {
  server.handleClient();  // Xử lý yêu cầu từ client
}