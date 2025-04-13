import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng ngày tháng

class OpenHistoryScreen extends StatefulWidget {
  const OpenHistoryScreen({super.key});

  @override
  _OpenHistoryScreenState createState() => _OpenHistoryScreenState();
}

class _OpenHistoryScreenState extends State<OpenHistoryScreen> {
  late DatabaseReference _ref;
  bool _initialized = false; // Đảm bảo chỉ khởi tạo 1 lần

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final String? lockId = ModalRoute.of(context)?.settings.arguments as String?;
      if (lockId != null) {
        _ref = FirebaseDatabase.instance.ref('lock/$lockId/open_history');
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
      appBar: AppBar(title: const Text('Lịch sử mở khóa')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final history = data.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key)); // Sắp xếp giảm dần

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                var entry = history[index].value;
                return ListTile(
                  title: Text("${entry['device']}: ${entry['method']}"),
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
