import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng ngày tháng

class OpenHistoryScreen extends StatefulWidget {
  final String lockId;

  const OpenHistoryScreen({super.key, required this.lockId});

  @override
  _OpenHistoryScreenState createState() => _OpenHistoryScreenState();
}

class _OpenHistoryScreenState extends State<OpenHistoryScreen> {
  DatabaseReference get _ref =>
      FirebaseDatabase.instance.ref('lock/${widget.lockId}/open_history');

  String formatTimestamp(String timestamp) {
    final dateTime =
    DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
    return DateFormat('HH:mm:ss dd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lịch sử mở khóa')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final history = data.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key)); // Sắp xếp theo key

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
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
