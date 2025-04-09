import 'package:flutter/material.dart';

import 'change_pin_code.dart';

class DeviceManagerScreen extends StatelessWidget {
  final TextEditingController deviceIdController = TextEditingController();

  DeviceManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test quản lý thiết bị'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: deviceIdController,
              decoration: InputDecoration(
                labelText: 'Nhập Device ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final deviceId = deviceIdController.text.trim();
                if (deviceId.isNotEmpty) {
                  showChangePinCodeBottomSheet(context, deviceId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập Device ID')),
                  );
                }
              },
              child: Text('Đổi mã khóa'),
            ),
          ],
        ),
      ),
    );
  }
}