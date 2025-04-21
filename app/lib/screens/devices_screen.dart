import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:app/widgets/custom_appbar.dart';

class DevicesScreen extends StatefulWidget {
  @override
  _DevicesScreenState createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final database = FirebaseDatabase.instance.ref();
  final auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> locks = [];

  @override
  void initState() {
    super.initState();
    _listenToUserLocks();
  }

  void _listenToUserLocks() {
    final uuid = auth.currentUser?.uid;
    if (uuid == null) return;

    final userLocksRef = database.child('account/$uuid/lock');

    userLocksRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is List) {
        List<Map<String, dynamic>> updatedLocks = [];
        for (var item in data) {
          if (item != null && item is Map) {
            updatedLocks.add({
              'id': item['id'],
              'name': item['name'],
              'message': item['latest_notification']?['message'] ?? '',
              'time': item['latest_notification']?['time'] ?? '',
            });
          }
        }

        setState(() {
          locks = updatedLocks;
        });
      }
    });
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp.toString().isEmpty) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          int.parse(timestamp.toString()) * 1000);
      return DateFormat('HH:mm:ss dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            CustomAppBar(subtitle: 'Quản lý thiết bị'),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/wifi_setup');
              },
              child: Text(
                "Thêm thiết bị",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 20),
            ...locks.map((lock) {
              return _buildSmartLockCard(
                name: lock['name'] ?? 'Không tên',
                message: lock['message'] ?? '',
                time: formatTimestamp(lock['time']),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/device_manager',
                    arguments: lock['id'],
                  );
                },
              );
            }).toList(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartLockCard({
    required String name,
    required String message,
    required String time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('$message: $time', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}