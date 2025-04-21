import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WifiSetupScreen extends StatefulWidget {
  @override
  _WifiSetupScreenState createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  bool isConnectingToSlock = true;
  bool isConnectingToWiFi = false;
  List<String> availableSSIDs = [];
  String? selectedSSID;
  String password = "";

  @override
  void initState() {
    super.initState();
    connectToSlockAP();
  }

  Future<void> connectToSlockAP() async {
    // Kết nối với mạng WiFi Slock_AP
    bool connected = await WiFiForIoTPlugin.connect(
      "Slock_AP",
      password: "12345678",
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false,
    );

    if (connected) {
      await Future.delayed(Duration(seconds: 3)); // đợi kết nối hoàn tất
      fetchAvailableNetworks();
    } else {
      setState(() {
        isConnectingToSlock = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể kết nối tới Slock_AP")),
      );
    }
  }

  Future<void> fetchAvailableNetworks() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.4.1/scan-wifi/"));
      if (response.statusCode == 200) {
        List<dynamic> ssids = json.decode(response.body);
        setState(() {
          isConnectingToSlock = false;
          availableSSIDs = ssids.cast<String>();
          if (availableSSIDs.isNotEmpty) {
            selectedSSID = availableSSIDs.first;
          }
        });
      } else {
        throw Exception("Lỗi khi quét WiFi");
      }
    } catch (e) {
      setState(() {
        isConnectingToSlock = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi lấy danh sách WiFi")),
      );
    }
  }

  Future<void> connectToSelectedWiFi() async {
    if (selectedSSID == null || password.isEmpty) return;

    setState(() {
      isConnectingToWiFi = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final uuid = user?.uid ?? "";

    final body = "ssid=${Uri.encodeComponent(selectedSSID!)}&password=${Uri.encodeComponent(password)}&uuid=${Uri.encodeComponent(uuid)}";

    try {
      final response = await http.post(
        Uri.parse("http://192.168.4.1/connect-wifi/"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kết nối WiFi thành công!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kết nối WiFi thất bại.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi gửi thông tin WiFi")),
      );
    } finally {
      setState(() {
        isConnectingToWiFi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isConnectingToSlock) {
      return Scaffold(
        appBar: AppBar(title: Text("Kết nối tới Slock_AP")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Thiết lập WiFi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: selectedSSID,
              items: availableSSIDs.map((ssid) {
                return DropdownMenuItem(
                  value: ssid,
                  child: Text(ssid),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSSID = val;
                });
              },
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true,
              onChanged: (val) => password = val,
              decoration: InputDecoration(
                labelText: "Mật khẩu WiFi",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            isConnectingToWiFi
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: connectToSelectedWiFi,
              child: Text("Kết nối"),
            ),
          ],
        ),
      ),
    );
  }
}
