import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

class WifiSetupScreen extends StatefulWidget {
  @override
  _WifiSetupScreenState createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  bool _isConnectingToAP = true;
  bool _isLoadingWifiList = false;
  List<String> _wifiList = [];
  String? _selectedSSID;
  String _password = '';
  final _formKey = GlobalKey<FormState>();
  bool _isDisposed = false; // Thêm biến kiểm tra disposed
  int _retryCount = 0;
  final int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _connectToSlockAP();
  }

  @override
  void dispose() {
    _isDisposed = true; // Đánh dấu khi widget bị hủy
    super.dispose();
  }

  Future<void> _connectToSlockAP() async {
    // Thêm trước khi gọi connect()
    var status = await Permission.location.request();
    if (!status.isGranted) {
      // Xử lý không có quyền
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ứng dụng cần quyền truy cập vị trí để kết nối WiFi')),
      );
      return; // Thoát nếu không có quyền
    }

    bool connected = false;
    while (!connected && !_isDisposed) {
      try {
        // Thử kết nối
        final success = await WiFiForIoTPlugin.connect(
          'Slock_AP',
          password: '12345678',
          joinOnce: false,
          security: NetworkSecurity.WPA,
        );

        // Thêm delay chờ SSID update
        await Future.delayed(Duration(seconds: 3));

        // Kiểm tra SSID thực tế
        String? currentSSID = await WiFiForIoTPlugin.getSSID();
        final isMatch = _isSSIDMatch(currentSSID);

        if (isMatch) {
          if (mounted && !_isDisposed) {
            setState(() => _isConnectingToAP = false);
            _fetchWifiList();
          }
          connected = true; // Thoát vòng lặp
        } else {
          await WiFiForIoTPlugin.disconnect();
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        if (!_isDisposed) print('Lỗi kết nối: ${e.toString()}');
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

// Hàm kiểm tra SSID flexible
  bool _isSSIDMatch(String? ssid) {
    if (ssid == null) return false;
    return ssid
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase()
        .contains('slockap');
  }

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<void> _fetchWifiList() async {
    if (_isDisposed) return;
    setState(() => _isLoadingWifiList = true);

    try {
      final response = await _dio.get('http://192.168.4.1/scan-wifi/');

      if (response.statusCode == 200 && !_isDisposed) {
        _retryCount = 0;
        List<dynamic> ssids = response.data;
        setState(() => _wifiList = ssids.cast<String>());
      } else if (!_isDisposed) {
        _handleRetry('Lỗi HTTP (dio): ${response.statusCode}');
      }
    } catch (e) {
      if (!_isDisposed) _handleRetry('Lỗi kết nối (dio): ${e.toString()}');
    } finally {
      if (!_isDisposed) setState(() => _isLoadingWifiList = false);
    }
  }

  void _handleRetry(String errorMessage) {
    print('$errorMessage - Thử lại (${_retryCount + 1}/$_maxRetries)');
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(Duration(seconds: 2), () {
        if (!_isDisposed) _fetchWifiList();
      });
    } else {
      _retryCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách WiFi sau $_maxRetries lần thử'),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () => _fetchWifiList(),
          ),
        ),
      );
    }
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cần cấp quyền vị trí để quét WiFi')),
      );
    }
  }

  Future<void> _connectToWifi() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_isDisposed) return; // Kiểm tra disposed

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
          'ssid': _selectedSSID!,
          'password': _password,
          'uuid': user.uid,
        },
      ).timeout(Duration(seconds: 15));

      if (!_isDisposed) {
        Navigator.pop(context);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thành công!'))
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kết nối thất bại: ${response.body}'))
          );
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi kết nối: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết lập WiFi'),
        actions: [
          if (!_isConnectingToAP)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _isLoadingWifiList ? null : _fetchWifiList,
              tooltip: 'Tải lại danh sách WiFi',
            ),
        ],
      ),
      body: _isConnectingToAP
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Đang kết nối Slock_AP...'),
            if (_retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Thử lại lần $_retryCount',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _isLoadingWifiList
                        ? LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                      value: _selectedSSID,
                      items: _wifiList
                          .map((ssid) => DropdownMenuItem(
                        value: ssid,
                        child: Text(ssid),
                      ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSSID = value),
                      decoration: InputDecoration(
                        labelText: 'Mạng WiFi',
                        border: OutlineInputBorder(),
                        suffixIcon: _isLoadingWifiList
                            ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                            : null,
                      ),
                      validator: (value) => value == null
                          ? 'Vui lòng chọn mạng WiFi'
                          : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  if (!_isLoadingWifiList)
                    IconButton(
                      icon: Icon(Icons.wifi_find),
                      onPressed: _fetchWifiList,
                      tooltip: 'Quét lại WiFi',
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
              ElevatedButton.icon(
                icon: Icon(Icons.wifi),
                label: Text('KẾT NỐI', style: TextStyle(fontSize: 18)),
                onPressed: _connectToWifi,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                ),
              ),
              if (_isLoadingWifiList)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Đang tải danh sách WiFi...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}