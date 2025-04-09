import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

void showChangePinCodeBottomSheet(BuildContext context, String lockId) {
  final TextEditingController newPinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();

  bool isObscured = true;
  String? newPinError;
  String? confirmPinError;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đổi mã khóa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Mã khóa 4 chữ số', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 16),

                TextField(
                  controller: newPinController,
                  obscureText: isObscured,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Mã khóa mới',
                    border: OutlineInputBorder(),
                    errorText: newPinError,
                  ),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: confirmPinController,
                  obscureText: isObscured,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mã khóa',
                    border: OutlineInputBorder(),
                    errorText: confirmPinError,
                  ),
                ),
                SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () async {
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();

                    // Reset lỗi trước khi kiểm tra
                    setState(() {
                      newPinError = null;
                      confirmPinError = null;
                    });

                    bool hasError = false;

                    if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
                      setState(() {
                        newPinError = 'Mã khóa phải là 4 chữ số thuộc 0-9';
                      });
                      hasError = true;
                    }

                    if (newPin != confirmPin) {
                      setState(() {
                        confirmPinError = 'Mã khóa không khớp';
                      });
                      hasError = true;
                    }

                    if (hasError) return;

                    try {
                      final DatabaseReference lockRef =
                      FirebaseDatabase.instance.ref('lock/$lockId/pin_code');
                      await lockRef.set(newPin);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã cập nhật mã khóa'), duration: Duration(seconds: 3)),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Có lỗi xảy ra')),
                      );
                    }
                  },
                  child: Text('Lưu'),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
