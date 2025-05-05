import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/custom_button.dart';

// Hàm hiển thị BottomSheet Chia sẻ Khóa
void showShareLockBottomSheet(BuildContext context, String lockId) {
  final TextEditingController secretCodeController = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  String? errorMessage;
  bool isLoading = false;
  String? qrDataString; // Chuỗi JSON chỉ chứa thông tin khóa
  String? generatedSecretCode; // Lưu mã bí mật đã dùng để tạo QR

  const String backendBaseUrl = "https://iot-smartlock-firmware.onrender.com";

  // Hàm gọi API set-secret-code (giữ nguyên logic hiện tại của API)
  Future<bool> setSecretCodeOnServer(String secretCode) async {
    // --- SỬA ĐỔI: Tạo URL với query parameter ---
    String code = lockId + secretCode;
    final queryParams = {'code': code};
    final url = Uri.parse('$backendBaseUrl/set-secret-code').replace(queryParameters: queryParams);
    // URL cuối cùng sẽ giống như: https://.../set-secret-code?code=kbsj9
    // -------------------------------------------

    try {
      print('Sending GET-style POST request to: $url'); // Log URL mới

      // --- SỬA ĐỔI: Gửi POST request không có body và header Content-Type ---
      final response = await http.post(
        url,
        // headers: {'Content-Type': 'application/json'}, // BỎ header này
        // body: jsonEncode({'code': codeToSend}),     // BỎ body này
      ).timeout(const Duration(seconds: 15));
      // --------------------------------------------------------------------

      print('Set Secret Code Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          // FastAPI vẫn có thể trả về JSON lỗi ngay cả khi input sai vị trí
          errorMessage = (errorData['detail'] is List && errorData['detail'].isNotEmpty)
              ? errorData['detail'][0]['msg'] // Lấy msg từ lỗi validation đầu tiên
              : (errorData['detail'] ?? 'Lỗi không xác định từ server.');
        } catch (_) {
          errorMessage = 'Lỗi ${response.statusCode} khi đặt mã bí mật.';
        }
        return false;
      }
    } catch (e) {
      print('Error calling set-secret-code API: $e');
      errorMessage = 'Không thể kết nối đến máy chủ chia sẻ.';
      return false;
    }
  }

  // Hàm lấy thông tin khóa từ Firebase để tạo QR (giữ nguyên)
  Future<Map<String, dynamic>?> getLockInfoForQR(String lockId) async {
    try {
      final lockRef = FirebaseDatabase.instance.ref('lock/$lockId');
      final snapshot = await lockRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final lockData = Map<String, dynamic>.from(snapshot.value as Map);
        return {
          'id': lockId,
          'name': lockData['name'] ?? 'Khóa không tên',
          // Chỉ lấy message và time từ latest_notification nếu cần
          'latest_notification': lockData['latest_notification']?['message'] != null
              ? {
            'message': lockData['latest_notification']['message'],
            'time': lockData['latest_notification']['time']
          }
              : null, // hoặc một giá trị mặc định
        };
      } else {
        errorMessage = 'Không tìm thấy thông tin khóa trên Firebase.';
        return null;
      }
    } catch (e) {
      print('Error fetching lock info from Firebase: $e');
      errorMessage = 'Lỗi lấy thông tin khóa.';
      return null;
    }
  }


  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 16
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Chia sẻ Khóa',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhập mã bí mật và tạo mã QR.\nNgười nhận cần quét mã QR VÀ nhập đúng mã bí mật này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: secretCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã bí mật (chia sẻ riêng)',
                    hintText: 'Nhập mã để người nhận xác thực',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // --- HIỂN THỊ QR VÀ MÃ BÍ MẬT ĐÃ DÙNG ---
                if (qrDataString != null && generatedSecretCode != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20), // Thêm khoảng cách dưới
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "1. Người nhận quét mã QR này:",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        QrImageView(
                          data: qrDataString!, // Chỉ chứa thông tin khóa
                          version: QrVersions.auto,
                          size: 200.0,
                          gapless: false,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "2. Cung cấp mã bí mật sau cho người nhận (nhập riêng):",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SelectableText( // Cho phép copy mã
                          generatedSecretCode!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "(Mã này chỉ dùng 1 lần và hết hạn sau 15 phút)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                // --------------------------------------

                const SizedBox(height: 0), // Giảm khoảng cách ở đây vì đã có margin ở trên

                CustomButton(
                  text: isLoading ? "Đang xử lý..." : (qrDataString == null ? "Tạo mã Chia sẻ" : "Tạo mã Khác"),
                  isLoading: isLoading,
                  onPressed: () async {
                    final secretCode = secretCodeController.text.trim();
                    if (secretCode.isEmpty) {
                      setState(() {
                        errorMessage = 'Vui lòng nhập mã bí mật.';
                        qrDataString = null;
                        generatedSecretCode = null;
                      });
                      return;
                    }

                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                      qrDataString = null;
                      generatedSecretCode = null;
                    });

                    // 1. Lấy thông tin khóa
                    final lockInfo = await getLockInfoForQR(lockId);

                    if (lockInfo != null) {
                      // 2. Gọi API để lưu mã bí mật
                      bool successSetCode = await setSecretCodeOnServer(secretCode);

                      if (successSetCode) {
                        // 3. Tạo chuỗi JSON cho QR (CHỈ chứa thông tin khóa)
                        qrDataString = jsonEncode(lockInfo); // Chỉ encode thông tin khóa
                        generatedSecretCode = secretCode; // Lưu lại mã đã dùng để hiển thị
                        print("QR Data String (Lock Info Only): $qrDataString");
                        print("Generated Secret Code: $generatedSecretCode");
                      }
                      // else: errorMessage đã được set
                    }
                    // else: errorMessage đã được set

                    setState(() { isLoading = false; });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}