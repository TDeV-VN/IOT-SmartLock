import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';

void showChangeLockNameBottomSheet(BuildContext context, String lockId) {
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
                'Đổi tên khóa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nhập tên mới cho ổ khóa',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khóa mới',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Nhà chính, Cổng sau...',
                ),
                maxLength: 30,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Lưu",
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) return;

                  try {
                    final lockRef = FirebaseDatabase.instance
                        .ref('account/$userId/lock');
                    final snapshot = await lockRef.get();

                    if (snapshot.exists) {
                      List<dynamic> locks = [];
                      if (snapshot.value is List) {
                        locks = List.from(snapshot.value as List);
                      } else if (snapshot.value is Map) {
                        locks = (snapshot.value as Map).values.toList();
                      }

                      final updatedLocks = locks.map((lock) {
                        if (lock is Map && lock['id'] == lockId) {
                          return {...lock, 'name': newName};
                        }
                        return lock;
                      }).toList();

                      await FirebaseDatabase.instance.ref().update({
                        'lock/$lockId/name': newName,
                        'account/$userId/lock': updatedLocks,
                      });

                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cập nhật tên thành $newName')),
                        );
                      }
                    }
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