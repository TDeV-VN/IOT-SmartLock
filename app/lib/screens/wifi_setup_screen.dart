import 'dart:convert';
import 'package:app/screens/add_device.dart';
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
  void initState() {
    super.initState();
    _loadWifiList();
  }

  @override
  void dispose() {
    _isDisposed = true; // Đánh dấu khi widget bị hủy
    super.dispose();
  }

  // Hàm gọi đến endpoint handleGetMac
  Future<String> _getMacAddress() async {
    const esp32Ip = '192.168.4.1'; // IP mặc định của ESP32 SoftAP
    final url = Uri.parse('http://$esp32Ip/mac/'); // Endpoint handleGetMac
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return response.body; // Trả về địa chỉ MAC
      } else {
        throw Exception('Failed to get MAC address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to ESP32: $e');
    }
  }

  // Hàm gọi đến endpoint handleShutdownAP
  Future<void> _shutdownAccessPoint() async {
    const esp32Ip = '192.168.4.1';
    // SỬA LẠI: Thêm dấu / vào cuối đường dẫn
    final url = Uri.parse('http://$esp32Ip/shutdown-ap/');

    // Dùng http client riêng và bỏ qua kết quả
    try {
      print('Sending GET request to $url to shutdown AP...'); // Thêm log để debug
      // SỬA LẠI: Sử dụng http.get thay vì http.post
      http.Client()
          .get(url) // <-- Thay đổi thành GET
          .timeout(const Duration(seconds: 2)) // Tăng nhẹ timeout phòng trường hợp mạng chậm
          .catchError((e) {
        // Vẫn bỏ qua lỗi, nhưng có thể log lại nếu cần debug
        print('Error sending shutdown command (ignored): $e');
      });
    } catch (e) {
      // Không làm gì nếu lỗi khởi tạo client (hiếm)
      print('Error initializing client for shutdown command: $e');
    }
    // Không cần await vì đây là "fire and forget"
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
        if (response.statusCode == 200) {
          print("KẾT NỐI THÀNH CÔNG: ${response.statusCode}");
          final macAddress = await _getMacAddress(); // lấy mac
          _shutdownAccessPoint(); // tắt AP
          Navigator.pop(context); // Đóng loading dialog

          // Gọi sheet và chờ kết quả (true, false, hoặc null)
          final bool? result = await showAddDeviceBottomSheetOptimized(context, macAddress);
          // Xử lý kết quả sau khi sheet đóng
          if (result == true) {
            print("Thêm khóa thành công!");
            // Mở /home
            Navigator.pushReplacementNamed(context, '/home');
          } else if (result == false) {
            print("Thêm khóa thất bại!");
          } else {
            print("Người dùng đã hủy thêm khóa.");
          }
        } else {
          Navigator.pop(context); // Đóng loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thất bại!'))
          );
          print('Kết nối thất bại: ${response.body}');
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi kết nối!'))
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
