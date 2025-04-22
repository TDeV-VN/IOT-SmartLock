import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showSetShareCodeBottomSheet(BuildContext context, String lockId) {
  final TextEditingController nameController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Thêm dòng này để cho phép scroll
    builder: (context) {
      return SingleChildScrollView( // Bọc bằng SingleChildScrollView
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16, // Thêm padding bottom cố định
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Quan trọng: phải là min
            children: [
              const SizedBox(height: 10),
              const Text(
                'Chia sẻ thiết bị',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gửi mã chia sẻ cho người khác',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tạo mã chia sẻ',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: 123456',
                ),
                maxLength: 30,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Lưu",
                onPressed: () async {
                  final code = nameController.text.trim();
                  if (code.isEmpty) return;

                  try {
                    // Gọi API để lưu mã chia sẻ
                    final response = await setSecretCode('$code|$lockId');
                    if (response != null && response.statusCode == 200) {

                      // final lockRef = FirebaseDatabase.instance
                      //     .ref('account/$userId/lock');
                      // final snapshot = await lockRef.get();
                      //
                      // if (snapshot.exists) {
                      //   List<dynamic> locks = [];
                      //   if (snapshot.value is List) {
                      //     locks = List.from(snapshot.value as List);
                      //   } else if (snapshot.value is Map) {
                      //     locks = (snapshot.value as Map).values.toList();
                      //   }
                      //
                      //   final updatedLocks = locks.map((lock) {
                      //     if (lock is Map && lock['id'] == lockId) {
                      //       lock['shareCode'] = code; // Lưu mã chia sẻ vào thiết bị
                      //     }
                      //     return lock;
                      //   }).toList();
                      //
                      //   await lockRef.set(updatedLocks); // Cập nhật lại Firebase
                      //   print('✅ Mã chia sẻ đã được lưu vào Firebase');
                      // }
                    } else {
                      print('❌ Failed to set code: ${response?.body}');
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 100), // Thêm khoảng cách an toàn
            ],
          ),
        ),
      );
    },
  );
}

Future<http.Response?> setSecretCode(String code) async {
  final url = Uri.parse('https://iot-smartlock-firmware.onrender.com/set-secret-code');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'code': code},
    );
    if (response.statusCode == 200) {
      print('✅ Secret code set successfully');
      return response;
    } else {
      print('❌ Failed to set code: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❗ Error: $e');
    return null;
  }
}
