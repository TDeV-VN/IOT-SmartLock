import 'package:flutter/material.dart';
import 'warning_history.dart';
import 'open_history.dart';
import 'change_pin_code.dart';

class DeviceManagerScreen extends StatelessWidget {
  final TextEditingController deviceIdController = TextEditingController();
  final String lockId;

  DeviceManagerScreen({super.key, required this.lockId}) {
    deviceIdController.text = lockId;
  }

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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showChangePinCodeBottomSheet(context, lockId);
              },
              child: Text('Đổi mã khóa'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WarningHistoryScreen(lockId: lockId)),
                );
              },
              child: Text('Xem lịch sử cảnh báo'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OpenHistoryScreen(lockId: lockId)),
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
