import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng ngày tháng

class WarningHistoryScreen extends StatefulWidget {
  const WarningHistoryScreen({super.key});

  @override
  _WarningHistoryScreenState createState() => _WarningHistoryScreenState();
}

class _WarningHistoryScreenState extends State<WarningHistoryScreen> {
  late DatabaseReference _ref;
  bool _initialized = false; // Để đảm bảo chỉ khởi tạo 1 lần

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final String? lockId = ModalRoute.of(context)?.settings.arguments as String?;
      if (lockId != null) {
        _ref = FirebaseDatabase.instance.ref('lock/$lockId/warning_history');
        _initialized = true;
      } else {
        throw Exception('lockId không được cung cấp qua arguments');
      }
    }
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    return DateFormat('HH:mm:ss dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cảnh báo')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<Object?, Object?> warningsMap =
            snapshot.data!.snapshot.value as Map<Object?, Object?>;

            List<Map<String, dynamic>> warnings = warningsMap.values
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            return ListView.builder(
              itemCount: warnings.length,
              itemBuilder: (context, index) {
                var entry = warnings[index];
                return ListTile(
                  title: Text(entry['message'] ?? 'Không có nội dung'),
                  subtitle: Text(formatTimestamp(entry['time'].toString())),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
