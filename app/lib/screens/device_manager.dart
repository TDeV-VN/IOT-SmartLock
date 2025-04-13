import 'package:flutter/material.dart';
import 'warning_history.dart';
import 'open_history.dart';
import 'change_pin_code.dart';

class DeviceManagerScreen extends StatelessWidget {
  DeviceManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? lockId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text('Test quản lý thiết bị'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showChangePinCodeBottomSheet(context, lockId!);
              },
              child: Text('Đổi mã khóa'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/warning_history',
                  arguments: lockId,
                );
              },
              child: Text('Xem lịch sử cảnh báo'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/open_history',
                  arguments: lockId,
                );
              },
              child: Text('Xem lịch sử mở khoá'),
            ),
          ],
        ),
      ),
    );
  }
}
