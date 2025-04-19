import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'change_lock_name.dart';
import 'warning_history.dart';
import 'open_history.dart';
import 'change_pin_code.dart';
import '../services/mqtt_handler.dart';

class DeviceManagerScreen extends StatelessWidget {
  DeviceManagerScreen({super.key});

  final mqtt = MQTTService();

  // Hàm hiển thị dialog với thiết kế thống nhất
  Widget _buildDialog({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    bool showProgress = false,
    List<Widget>? actions,
    bool barrierDismissible = false,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
      content: contentWidget ?? (content != null
          ? Text(
        content,
        style: TextStyle(fontSize: 16),
      )
          : null),
      actions: actions,
      actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 8),
      titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      actionsAlignment: MainAxisAlignment.end,
      buttonPadding: EdgeInsets.symmetric(horizontal: 8),
      insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      elevation: 8,
      backgroundColor: Colors.white,
    );
  }

  void checkFirmware(BuildContext context, String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final topic = 'esp32/$lockId/$userId';
    final responseTopic = '$topic/response';
    final client = mqtt.client;

    client.subscribe(responseTopic, MqttQos.atMostOnce);

    late final StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> subscription;

    // Hiển thị dialog kiểm tra firmware
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialog(
        context: context,
        title: 'Kiểm tra Firmware',
        contentWidget: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Đang kiểm tra phiên bản firmware...',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              subscription.cancel();
              mqtt.disconnect();
            },
            child: Text(
              'HỦY',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    subscription = client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topicReceived = c[0].topic;

      if (topicReceived == responseTopic) {
        Navigator.pop(context); // Đóng dialog loading

        final data = jsonDecode(payload);
        final current = data['current'];
        final latest = data['latest'];

        showDialog(
          context: context,
          builder: (_) => _buildDialog(
            context: context,
            title: 'Thông tin Firmware',
            content: 'Phiên bản hiện tại: $current\nPhiên bản mới nhất: $latest',
            actions: [
              if (current != latest)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    updateFirmware(context, lockId);
                  },
                  child: Text(
                    'CẬP NHẬT',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ĐÓNG',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        subscription.cancel();
        mqtt.disconnect();
      }
    });

    mqtt.publishMessage(topic, 'CheckFirmware');
  }

  void updateFirmware(BuildContext context, String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final topic = 'esp32/$lockId/$userId';
    final responseTopic = '$topic/response';
    final client = mqtt.client;

    client.subscribe(responseTopic, MqttQos.atMostOnce);

    late final StreamSubscription<List<MqttReceivedMessage<MqttMessage>>> subscription;

    // Hiển thị dialog cập nhật firmware
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildDialog(
        context: context,
        title: 'Cập nhật Firmware',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải và cài đặt phiên bản mới...',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng không tắt thiết bị',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    subscription = client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topicReceived = c[0].topic;

      if (topicReceived == responseTopic) {
        final data = jsonDecode(payload);
        final updateFirmware = data['updateFirmware'];

        Navigator.pop(context); // Đóng dialog loading

        if (updateFirmware == 'success') {
          showDialog(
            context: context,
            builder: (_) => _buildDialog(
              context: context,
              title: 'Thành công',
              content: 'Cập nhật firmware thành công!\nThiết bị sẽ tự động khởi động lại.',
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ĐÓNG',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => _buildDialog(
              context: context,
              title: 'Thất bại',
              content: 'Cập nhật firmware không thành công.\nVui lòng thử lại sau.',
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ĐÓNG',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    this.updateFirmware(context, lockId);
                  },
                  child: Text(
                    'THỬ LẠI',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        subscription.cancel();
        mqtt.disconnect();
      }
    });

    mqtt.publishMessage(topic, 'UpdateFirmware'); // Sửa thành UpdateFirmware thay vì CheckFirmware
  }

  @override
  Widget build(BuildContext context) {
    final String? lockId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý thiết bị'),
        centerTitle: true,
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
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Đổi mã khóa'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Xem lịch sử cảnh báo'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Xem lịch sử mở khoá'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showChangeLockNameBottomSheet(context, lockId!);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Đổi tên khóa'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                checkFirmware(context, lockId!);
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Cập nhật firmware'),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}