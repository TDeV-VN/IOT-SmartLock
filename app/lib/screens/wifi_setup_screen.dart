import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/custom_button.dart';

class WifiSetupScreen extends StatefulWidget {
  @override
  _WifiSetupScreenState createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  bool _isLoadingWifiList = false;
  List<String> _wifiList = [];
  String? _selectedSSID;
  String _password = '';
  final _formKey = GlobalKey<FormState>();
  bool _isDisposed = false; // Thêm biến kiểm tra disposed

  @override
  void dispose() {
    _isDisposed = true; // Đánh dấu khi widget bị hủy
    super.dispose();
  }

  Future<void> _loadWifiList() async {
    setState(() {
      _isLoadingWifiList = true;
    });

    try {
      final result = await _scanWifi();
      if (!_isDisposed) {
        setState(() {
          _wifiList = result;
          _selectedSSID = result.isNotEmpty ? result.first : null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể quét WiFi: $e')),
      );
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingWifiList = false;
        });
      }
    }
  }

  Future<List<String>> _scanWifi() async {
    const esp32Ip = '192.168.4.1'; // IP mặc định của ESP32 SoftAP
    final url = Uri.parse('http://$esp32Ip/scan-wifi/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("QUÉT THÀNH CÔNG: ${response.statusCode}");
        return data.cast<String>();
      } else {
        print("QUÉT THẤT BẠI: ${response.statusCode}");
        throw Exception('Failed to scan WiFi: ${response.statusCode}');
      }
    } catch (e) {
      print("LỖI KẾT NỐI: $e");
      throw Exception('Failed to connect to ESP32: $e');
    }
  }

  Future<void> _connectToWifi() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_isDisposed) return; // Kiểm tra widget đã bị hủy hay chưa

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng đăng nhập trước'))
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse('http://192.168.4.1/connect-wifi/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'ssid': _selectedSSID!,  // Mạng WiFi được chọn
          'password': _password,   // Mật khẩu WiFi
          'uuid': user.uid,        // UUID từ Firebase Auth
        },
      ).timeout(Duration(seconds: 10));

      if (!_isDisposed) {
        Navigator.pop(context); // Đóng loading dialog
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thành công!'))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thất bại: ${response.body}'))
          );
          print('Kết nối thất bại: ${response.body}');
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi kết nối: ${e.toString()}'))
        );
        print('Lỗi kết nối: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm thiết bị'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoadingWifiList ? null : _loadWifiList,
            tooltip: 'Tải lại danh sách WiFi',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              Text(
                '1. Kết nối với mạng WiFi "Slock_AP |12345678"\n\n'
                    '2. Chọn và kết nối mạng WiFi cho khóa cửa',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 50),
              Row(
                children: [
                  Expanded(
                    child: _isLoadingWifiList
                        ? LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                      value: _selectedSSID,
                      items: _wifiList.map((ssid) {
                        return DropdownMenuItem(
                          value: ssid,
                          child: Text(ssid),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSSID = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Mạng WiFi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null ? 'Vui lòng chọn mạng WiFi' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 30),
              CustomButton(
                text: "Kết nối",
                onPressed: _connectToWifi,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
