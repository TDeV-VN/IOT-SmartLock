import 'package:flutter/cupertino.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng ngày tháng

class OpenHistoryScreen extends StatefulWidget {
  @override
  _OpenHistoryScreenState createState() => _OpenHistoryScreenState();
}

class _OpenHistoryScreenState extends State<OpenHistoryScreen> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('lock/lock_id1/open_history');

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
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
            List<dynamic> history = snapshot.data!.snapshot.value as List<dynamic>;
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                var entry = history[index];
                return ListTile(
                  title: Text("${entry['device']}: ${entry['method']}"),
                  subtitle: Text(formatTimestamp(entry['time'])),
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