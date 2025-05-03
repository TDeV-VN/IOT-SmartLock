import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/custom_button.dart';

// --- Hàm Tối Ưu: Chỉ xử lý Firebase, trả về true/false ---
Future<bool> _addLockToFirebaseOptimized({
  // Không cần BuildContext ở đây nữa nếu chỉ dùng để lấy currentUser
  // required BuildContext context,
  required String lockId,
  required String name,
  required String newPin,
}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print("Lỗi: Người dùng chưa đăng nhập trong _addLockToFirebaseOptimized.");
    return false; // Trả về lỗi nếu không có user
  }
  final userId = currentUser.uid;

  // --- Loại bỏ hoàn toàn các tương tác UI khỏi hàm này ---
  // showDialog(...); // XÓA
  // Navigator.pop(...); // XÓA
  // ScaffoldMessenger... // XÓA

  try {
    // 1. Lấy danh sách khóa hiện tại (Logic giữ nguyên nhưng có thể tối ưu nhẹ)
    final DatabaseReference userLocksRef = FirebaseDatabase.instance.ref('account/$userId/lock');
    final DataSnapshot snapshot = await userLocksRef.get();

    List<Object?> currentLocks = [];
    if (snapshot.exists && snapshot.value is List) {
      // Xử lý an toàn hơn khi cast
      try {
        currentLocks = List<Object?>.from(snapshot.value as List);
      } catch (e) {
        print("Lỗi khi cast user lock list: ${snapshot.value}. Lỗi: $e");
        // Xem xét tạo list rỗng hoặc xử lý khác tùy logic
        currentLocks = [];
      }
    }

    // 2. Tạo đối tượng khóa mới cho danh sách người dùng
    final newLockForUserList = {
      'id': lockId,
      'name': name,
      'latest_notification': {
        'message': 'Khóa đã được thêm',
        'time': ServerValue.timestamp, // Dùng timestamp server
      }
    };

    // 3. Cập nhật danh sách khóa của người dùng (Tìm và cập nhật hoặc thêm mới)
    int existingIndex = currentLocks.indexWhere((lock) => lock is Map && lock['id'] == lockId);
    List<Object?> updatedLockList = List.from(currentLocks); // Tạo bản sao

    if (existingIndex != -1) {
      // Cập nhật khóa đã tồn tại
      print("Thông báo: Cập nhật thông tin khóa $lockId trong danh sách người dùng.");
      (updatedLockList[existingIndex] as Map)['name'] = name;
      (updatedLockList[existingIndex] as Map)['latest_notification'] = {
        'message': 'Thông tin khóa được cập nhật',
        'time': ServerValue.timestamp,
      };
    } else {
      // Thêm khóa mới
      print("Thông báo: Thêm mới khóa $lockId vào danh sách người dùng.");
      updatedLockList.add(newLockForUserList);
    }

    // 4. Chuẩn bị dữ liệu cập nhật đa đường dẫn
    final Map<String, Object?> updates = {};

    // Thêm địa chỉ MAC đầy đủ (có dấu :) vào dữ liệu khóa chính
    final String fullMacAddress = (lockId.length == 12)
        ? lockId.replaceAllMapped(RegExp(r'(.{2})(?!$)'), (match) => '${match[1]}:')
        : lockId; // Giữ nguyên nếu định dạng không đúng

    // Đường dẫn 1: Dữ liệu chính của khóa
    updates['lock/$lockId'] = {
      'name': name,
      'pin_code': newPin,
      'locking_status': true, // Mặc định khóa
      'uuid': userId,         // Người sở hữu
      'open_history': {},     // Khởi tạo rỗng
      'warning_history': {},  // Khởi tạo rỗng
    };

    // Đường dẫn 2: Cập nhật toàn bộ danh sách khóa của người dùng
    updates['account/$userId/lock'] = updatedLockList;

    // 5. Thực hiện cập nhật nguyên tử
    await FirebaseDatabase.instance.ref().update(updates);

    // 6. Thành công: trả về true
    print("Firebase update thành công cho lockId: $lockId");
    return true;

  } catch (e) {
    // 7. Thất bại: In lỗi và trả về false
    print("Lỗi nghiêm trọng khi cập nhật Firebase: $e");
    // Có thể log chi tiết hơn nếu e là DatabaseError
    // if (e is DatabaseError) { print(e.details); }
    return false;
  }
}


// Trả về Future<bool?>: true=thành công, false=thất bại, null=hủy
Future<bool?> showAddDeviceBottomSheetOptimized(BuildContext context, String lockId) async {
  final TextEditingController newPinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // Trả về kết quả khi sheet đóng
  return await showModalBottomSheet<bool?>(
    context: context,
    isScrollControlled: true, // Cho phép sheet cao
    isDismissible: true,      // Cho phép đóng khi chạm bên ngoài
    enableDrag: true,         // Cho phép kéo xuống để đóng
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) { // Context của sheet
      // Dùng StatefulBuilder để quản lý trạng thái nội bộ của sheet
      return StatefulBuilder(
        builder: (statefulContext, setState) {
          // Trạng thái nội bộ
          bool isPinObscured = true;
          String? newPinError;
          String? confirmPinError;
          String? nameError;
          bool isLoading = false; // <<=== Quản lý trạng thái loading

          // --- Hàm xử lý khi nhấn nút Lưu ---
          Future<void> handleSave() async {
            final newPin = newPinController.text.trim();
            final confirmPin = confirmPinController.text.trim();
            final name = nameController.text.trim();

            // --- Validate Input ---
            setState(() { // Reset lỗi trước khi validate
              newPinError = null;
              confirmPinError = null;
              nameError = null;
            });
            bool hasError = false;

            if (name.isEmpty) {
              setState(() { nameError = 'Tên khóa không được để trống'; });
              hasError = true;
            }
            if (newPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(newPin)) {
              setState(() { newPinError = 'Mã khóa phải là 4 chữ số'; });
              hasError = true;
            }
            // Chỉ kiểm tra khớp nếu PIN mới hợp lệ
            if (!hasError && newPin != confirmPin) {
              setState(() { confirmPinError = 'Mã khóa không khớp'; });
              hasError = true;
            }

            if (hasError) return; // Dừng nếu có lỗi validate

            // --- Bắt đầu xử lý ---
            if (!statefulContext.mounted) return; // Kiểm tra trước khi setState
            setState(() { isLoading = true; }); // Hiển thị loading trên nút

            // Gọi hàm Firebase đã tối ưu và đợi kết quả
            bool success = await _addLockToFirebaseOptimized(
              // context: statefulContext, // Không cần context nữa
              lockId: lockId,
              name: name,
              newPin: newPin,
            );

            // --- Kết thúc xử lý ---
            if (!statefulContext.mounted) return; // Kiểm tra sau await
            setState(() { isLoading = false; }); // Tắt loading

            // --- Xử lý kết quả và UI ---
            if (sheetContext.mounted) { // Kiểm tra sheet còn tồn tại không
              // Đóng sheet VÀ trả về kết quả (true/false)
              Navigator.of(sheetContext).pop(success);

              // Hiển thị SnackBar trên context gốc (vì sheet sắp bị hủy)
              if (context.mounted) { // Kiểm tra context gốc
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã thêm khóa "$name" thành công!' : 'Thêm khóa thất bại. Vui lòng thử lại.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          } // --- Kết thúc handleSave ---

          // --- Giao diện UI của BottomSheet ---
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(statefulContext).viewInsets.bottom, // Xử lý bàn phím
              top: 16, left: 16, right: 16,
            ),
            child: SingleChildScrollView( // Tránh overflow khi bàn phím hiện
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Thêm Khóa Mới', textAlign: TextAlign.center, style: Theme.of(statefulContext).textTheme.titleLarge),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text('Nhập tên và mã khóa (PIN) 4 chữ số.', textAlign: TextAlign.center, style: Theme.of(statefulContext).textTheme.bodyMedium),
                  ),

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên khóa',
                      hintText: 'Ví dụ: Nhà chính, Cổng sau',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.label_outline),
                      errorText: nameError,
                    ),
                    onChanged: (_) => setState(() => nameError = null), // Xóa lỗi khi nhập
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: newPinController,
                    obscureText: isPinObscured,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Mã khóa mới (4 số)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.pin_outlined),
                      errorText: newPinError,
                      suffixIcon: IconButton(
                        icon: Icon(isPinObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => isPinObscured = !isPinObscured),
                      ),
                      counterText: "", // Ẩn counter
                    ),
                    onChanged: (value) {
                      setState(() => newPinError = null);
                      if (value.length == 4) FocusScope.of(statefulContext).nextFocus(); // Auto next focus
                    },
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: confirmPinController,
                    obscureText: isPinObscured,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mã khóa',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: Icon(Icons.pin_outlined),
                      errorText: confirmPinError,
                      suffixIcon: IconButton(
                        icon: Icon(isPinObscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => isPinObscured = !isPinObscured),
                      ),
                      counterText: "",
                    ),
                    onChanged: (_) => setState(() => confirmPinError = null),
                    onEditingComplete: isLoading ? null : handleSave, // Submit on done
                  ),
                  SizedBox(height: 24),
                  CustomButton(
                    text: "Thêm Khóa",
                    onPressed: handleSave,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// --- Ví dụ cách gọi hàm tối ưu ---
/*
Future<void> triggerAddDeviceFlow(BuildContext context, String lockIdFromESP) async {
  if (!context.mounted) return; // Kiểm tra context trước khi dùng

  final String lockId = lockIdFromESP.replaceAll(':', ''); // Lấy ID khóa

  // Gọi sheet và chờ kết quả (true, false, hoặc null)
  final bool? result = await showAddDeviceBottomSheetOptimized(context, lockId);

  // Xử lý kết quả sau khi sheet đóng
  if (result == true) {
    print("Thêm khóa thành công! (Xử lý tại nơi gọi)");
    // Điều hướng hoặc cập nhật UI khác
  } else if (result == false) {
    print("Thêm khóa thất bại! (Xử lý tại nơi gọi)");
    // Có thể hiển thị thông báo lỗi khác nếu cần
  } else {
    // result == null (Người dùng hủy sheet)
    print("Người dùng đã hủy thêm khóa.");
  }
}
*/