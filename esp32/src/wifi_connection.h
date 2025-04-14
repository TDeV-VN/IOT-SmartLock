#ifndef WIFI_CONNECTION_H
#define WIFI_CONNECTION_H

#include <WiFi.h>
#include <WebServer.h>
#include "Preference.h"  

extern WebServer server;  // Đối tượng server sẽ được khai báo ở một nơi duy nhất

void handleScanWifi();      // Hàm quét Wi-Fi
void handleConnectWifi();   // Hàm kết nối Wi-Fi
void handleMac();           // Hàm lấy MAC address
void startServer();         // Hàm khởi động WebServer
void handleWifiClient();    // Hàm xử lý client

#endif