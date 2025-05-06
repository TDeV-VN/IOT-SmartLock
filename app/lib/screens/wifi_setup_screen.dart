import 'dart:convert';
import 'package:app/screens/add_device.dart'; // Đảm bảo import này đúng
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart'; // Đảm bảo import này đúng

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
  bool _isDisposed = false;

  bool _isManualSsidInput = false;
  final TextEditingController _manualSsidController = TextEditingController();
  String _manualSSIDValue = '';

  @override
  void initState() {
    super.initState();
    _loadWifiList();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _manualSsidController.dispose();
    super.dispose();
  }

  Future<String> _getMacAddress() async {
    const esp32Ip = '192.168.4.1';
    final url = Uri.parse('http://$esp32Ip/mac/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to get MAC address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to ESP32: $e');
    }
  }

  Future<void> _shutdownAccessPoint() async {
    const esp32Ip = '192.168.4.1';
    final url = Uri.parse('http://$esp32Ip/shutdown-ap/');
    try {
      print('Sending GET request to $url to shutdown AP...');
      http.Client()
          .get(url)
          .timeout(const Duration(seconds: 2))
          .catchError((e) {
        print('Error sending shutdown command (ignored): $e');
      });
    } catch (e) {
      print('Error initializing client for shutdown command: $e');
    }
  }

  Future<void> _loadWifiList() async {
    if (_isDisposed) return;
    setState(() {
      _isLoadingWifiList = true;
    });

    try {
      final result = await _scanWifi();
      if (!_isDisposed) {
        setState(() {
          _wifiList = result;
          if (!_isManualSsidInput) {
            if (result.isNotEmpty) {
              if (_selectedSSID == null || !result.contains(_selectedSSID)) {
                _selectedSSID = result.first;
              }
            } else {
              _selectedSSID = null;
            }
          }
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) { // Thêm `mounted` để an toàn hơn
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể quét WiFi: $e')),
        );
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingWifiList = false;
        });
      }
    }
  }

  Future<List<String>> _scanWifi() async {
    const esp32Ip = '192.168.4.1';
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

    if (_isDisposed) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vui lòng đăng nhập trước'))
        );
      }
      return;
    }

    String ssidToConnect;
    if (_isManualSsidInput) {
      ssidToConnect = _manualSSIDValue;
    } else {
      if (_selectedSSID == null) {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Vui lòng chọn mạng WiFi'))
          );
        }
        return;
      }
      ssidToConnect = _selectedSSID!;
    }

    if (!_isDisposed && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.4.1/connect-wifi/'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'ssid': ssidToConnect,
          'password': _password,
          'uuid': user.uid,
        },
      ).timeout(Duration(seconds: 15)); // Tăng nhẹ timeout cho kết nối

      if (!_isDisposed && mounted) {
        Navigator.pop(context); // Đóng loading dialog
        if (response.statusCode == 200) {
          print("KẾT NỐI THÀNH CÔNG: ${response.statusCode}");
          final macAddress = await _getMacAddress();
          _shutdownAccessPoint();

          final bool? result = await showAddDeviceBottomSheetOptimized(context, macAddress);
          if (!_isDisposed && mounted) {
            if (result == true) {
              print("Thêm khóa thành công!");
              Navigator.pushReplacementNamed(context, '/home');
            } else if (result == false) {
              print("Thêm khóa thất bại!");
            } else {
              print("Người dùng đã hủy thêm khóa.");
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thất bại: ${response.body}'))
          );
          print('Kết nối thất bại: ${response.body}');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
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
      // === SỬA ĐỔI: Bọc Padding bằng SingleChildScrollView ===
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30),
                Text(
                  '1. Kết nối với mạng WiFi "Slock_AP |12345678"\n\n'
                      '2. Chọn hoặc nhập và kết nối mạng WiFi cho khóa cửa', // Cập nhật text hướng dẫn
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                CheckboxListTile(
                  title: Text("Nhập SSID WiFi thủ công"),
                  value: _isManualSsidInput,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isManualSsidInput = newValue ?? false;
                      _formKey.currentState?.reset(); // Reset trạng thái validation
                      if (_isManualSsidInput) {
                        if (_selectedSSID != null) {
                          _manualSsidController.text = _selectedSSID!;
                        }
                      } else {
                        _manualSsidController.clear();
                        if (_wifiList.isNotEmpty && (_selectedSSID == null || !_wifiList.contains(_selectedSSID))) {
                          _selectedSSID = _wifiList.first;
                        }
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                SizedBox(height: 20),
                if (_isManualSsidInput)
                  TextFormField(
                    controller: _manualSsidController,
                    decoration: InputDecoration(
                      labelText: 'SSID WiFi (thủ công)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wifi_tethering),
                    ),
                    validator: (value) {
                      if (_isManualSsidInput && (value == null || value.isEmpty)) {
                        return 'Vui lòng nhập SSID';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _manualSSIDValue = value ?? '';
                    },
                  )
                else
                  _isLoadingWifiList
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height:8), Text("Đang quét Wi-Fi...")]))
                      : _wifiList.isEmpty && !_isLoadingWifiList
                      ? Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Text("Không tìm thấy mạng WiFi nào.", textAlign: TextAlign.center),
                        Text("Hãy thử làm mới hoặc chọn nhập thủ công.", textAlign: TextAlign.center),
                      ],
                    ),
                  ))
                      : DropdownButtonFormField<String>(
                    value: _selectedSSID,
                    items: _wifiList.map((ssid) {
                      return DropdownMenuItem(
                        value: ssid,
                        child: Text(ssid, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSSID = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Chọn Mạng WiFi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isManualSsidInput && value == null) {
                        return 'Vui lòng chọn mạng WiFi';
                      }
                      return null;
                    },
                    isExpanded: true,
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
                SizedBox(height: 20), // Thêm khoảng trống ở cuối để tránh bị che khuất khi cuộn
              ],
            ),
          ),
        ),
      ),
      // === KẾT THÚC SỬA ĐỔI ===
    );
  }
}

/*
// --- Bỏ comment và sửa nếu bạn cần test riêng màn hình này ---
// --- Đây là một hàm giả lập cho showAddDeviceBottomSheetOptimized ---
// --- Bạn cần thay thế bằng hàm thực tế từ project của bạn ---
Future<bool?> showAddDeviceBottomSheetOptimized(BuildContext context, String macAddress) async {
  print("showAddDeviceBottomSheetOptimized called with MAC: $macAddress");
  // Giả lập độ trễ mạng
  // await Future.delayed(Duration(seconds: 2));
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // Quan trọng nếu bottom sheet có nội dung động
    builder: (BuildContext bc) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(bc).viewInsets.bottom), // Để tránh bàn phím che
        child: Container(
          padding: EdgeInsets.all(20),
          child: Wrap(
            children: <Widget>[
              Text("Thêm khóa với MAC: $macAddress", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 20),
              // Giả sử có một TextFormField trong bottom sheet
              // TextField(decoration: InputDecoration(labelText: "Tên thiết bị")),
              // SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Giả lập: Thêm thành công'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: Text('Giả lập: Thêm thất bại'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Giả lập: Hủy bỏ'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      );
    },
  );
}
*/