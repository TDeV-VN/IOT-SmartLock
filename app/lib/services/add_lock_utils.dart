import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
// import 'package:qr_flutter/qr_flutter.dart'; // Không cần cho sheet này
import '../widgets/custom_button.dart'; // Import CustomButton

// --- HÀM XÁC THỰC MÃ BÍ MẬT TRÊN SERVER ---
Future<bool> validateSecretCodeOnServer(String secretCode) async {
  const String backendBaseUrl = "https://iot-smartlock-firmware.onrender.com";

  // --- TẠO URL VỚI QUERY PARAMETER ---
  final queryParams = {'code': secretCode};
  final url = Uri.parse('$backendBaseUrl/validate-secret-code').replace(queryParameters: queryParams);
  // Ví dụ URL: https://..../validate-secret-code?code=yourSecretCode
  // ------------------------------------

  String? localErrorMessage; // Biến lỗi cục bộ (có thể không cần nếu ném Exception)

  try {
    print('Validating secret code via URL: $url');

    // --- GỬI POST REQUEST KHÔNG CÓ BODY VÀ HEADER CONTENT-TYPE JSON ---
    final response = await http.post(
      url,
      // Không cần headers: {'Content-Type': 'application/json'},
      // Không cần body: jsonEncode({'code': secretCode}),
    ).timeout(const Duration(seconds: 15));
    // ---------------------------------------------------------------

    print('Validate Secret Code Response: ${response.statusCode} - ${response.body}');

    // Xử lý phản hồi từ Server
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        // Kiểm tra cả key 'valid' tồn tại và giá trị là true
        if (responseData['valid'] == true) {
          print("Secret code is valid.");
          return true; // Mã hợp lệ
        } else {
          // Server trả về 200 nhưng valid=false hoặc không có key 'valid'
          localErrorMessage = "Mã bí mật không hợp lệ hoặc đã hết hạn (Code 200).";
          print("Secret code is invalid (valid: false or missing).");
          // Ném Exception thay vì chỉ trả về false để hàm gọi biết lý do
          throw Exception(localErrorMessage);
          // return false;
        }
      } catch(e) {
        // Lỗi parse JSON phản hồi 200? Phản hồi không đúng định dạng
        print("Error parsing successful response JSON: $e");
        throw Exception("Phản hồi từ server không hợp lệ.");
      }
    } else if (response.statusCode == 404) {
      // Lỗi 404 thường có nghĩa là endpoint đúng nhưng không tìm thấy tài nguyên (code)
      localErrorMessage = "Mã bí mật không tồn tại hoặc đã hết hạn (Code 404).";
      print("Secret code not found or expired (404).");
      throw Exception(localErrorMessage);
      // return false;
    }
    // Bỏ qua kiểm tra lỗi 400 cụ thể vì chúng ta không biết chắc backend trả về gì
    // else if (response.statusCode == 400 && ...) { ... }
    else {
      // Các lỗi khác (422 nếu URL sai, 5xx, ...)
      String detailMessage = 'Lỗi không xác định từ server.'; // Mặc định
      try {
        final errorData = jsonDecode(response.body);
        // Cố gắng lấy thông điệp lỗi chi tiết hơn
        if (errorData['detail'] is List && errorData['detail'].isNotEmpty) {
          detailMessage = errorData['detail'][0]['msg'] ?? detailMessage;
        } else if (errorData['detail'] is String) {
          detailMessage = errorData['detail'];
        }
      } catch (_) {
        // Không parse được JSON lỗi, dùng mã lỗi HTTP
        detailMessage = 'Lỗi ${response.statusCode} khi xác thực mã.';
      }
      localErrorMessage = detailMessage;
      print("Validation failed with status ${response.statusCode}. Detail: $localErrorMessage");
      throw Exception(localErrorMessage); // Ném lỗi
      // return false;
    }
  } on TimeoutException catch (_) {
    print('Validate secret code request timed out.');
    throw Exception('Hết thời gian chờ phản hồi từ máy chủ.');
  }
  catch (e) {
    // Bắt các lỗi khác (ví dụ: lỗi mạng, lỗi parse URL) và các Exception đã ném ở trên
    print('Error calling validate-secret-code API: $e');
    // Ném lại lỗi hoặc một Exception chung hơn
    throw Exception('Không thể kết nối đến máy chủ xác thực.');
  }
}

// --- HÀM THÊM KHÓA VÀO DANH SÁCH CỦA NGƯỜI NHẬN ---
Future<bool> addLockToReceiverFirebase(String receiverUserId, Map<String, dynamic> lockInfoToAdd) async {
  final lockIdToAdd = lockInfoToAdd['id'] as String?;
  if (lockIdToAdd == null) {
    print("Error: Lock ID missing in lockInfoToAdd");
    return false; // Thiếu ID khóa
  }

  final DatabaseReference userLocksRef = FirebaseDatabase.instance.ref('account/$receiverUserId/lock');

  try {
    print("Attempting to add lock $lockIdToAdd for user $receiverUserId");
    // 1. Đọc danh sách khóa hiện tại
    final snapshot = await userLocksRef.get();
    List<Object?> currentLocks = [];
    if (snapshot.exists && snapshot.value is List) {
      try {
        currentLocks = List<Object?>.from(snapshot.value as List);
      } catch(e) {
        print("Error casting current user locks: $e. Starting with empty list.");
        currentLocks = [];
      }
    } else if (snapshot.exists) {
      print("Warning: User lock data exists but is not a list. Overwriting with new list.");
      currentLocks = []; // Sẽ ghi đè nếu dữ liệu cũ không phải list
    }

    // 2. Kiểm tra trùng lặp
    bool alreadyExists = currentLocks.any((lock) => lock is Map && lock['id'] == lockIdToAdd);
    if (alreadyExists) {
      print("Lock $lockIdToAdd already exists for user $receiverUserId.");
      // Có thể coi đây là thành công vì khóa đã có trong danh sách
      return true; // Hoặc trả về một giá trị đặc biệt để báo đã tồn tại
    }

    // 3. Tạo object khóa mới cho danh sách người dùng
    // Đảm bảo chỉ lấy các trường cần thiết từ lockInfoToAdd
    final newLockEntry = {
      'id': lockInfoToAdd['id'],
      'name': lockInfoToAdd['name'] ?? 'Khóa mới', // Lấy tên từ QR hoặc đặt mặc định
      'latest_notification': lockInfoToAdd['latest_notification'], // Lấy thông báo từ QR
    };

    // 4. Thêm vào danh sách và ghi lại
    List<Object?> updatedLockList = List.from(currentLocks);
    updatedLockList.add(newLockEntry);

    print("Writing updated lock list back to Firebase for user $receiverUserId");
    await userLocksRef.set(updatedLockList); // Ghi đè toàn bộ danh sách
    print("Successfully added lock $lockIdToAdd to user $receiverUserId list.");
    return true;

  } catch (e) {
    print("Error adding lock to Firebase for user $receiverUserId: $e");
    // Ném lại lỗi để hàm gọi xử lý
    throw Exception('Lỗi cập nhật danh sách khóa.');
  }
}


// --- HÀM HIỂN THỊ BOTTOMSHEET XÁC THỰC & THÊM KHÓA ---
void showValidateAndAddLockBottomSheet(BuildContext context, Map<String, dynamic> scannedLockInfo) {
  final TextEditingController secretCodeController = TextEditingController();
  final receiverUserId = FirebaseAuth.instance.currentUser?.uid;
  final lockIdFromQR = scannedLockInfo['id'] as String?;
  final lockNameFromQR = scannedLockInfo['name'] as String?;

  // Kiểm tra dữ liệu đầu vào cơ bản
  if (receiverUserId == null) {
    print("Error: Receiver user not logged in.");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Bạn chưa đăng nhập.')));
    return;
  }
  if (lockIdFromQR == null || lockNameFromQR == null) {
    print("Error: Invalid QR data received.");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Dữ liệu QR không hợp lệ.')));
    return;
  }

  String? errorMessage;
  bool isLoading = false;

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
                  'Thêm Khóa Được Chia Sẻ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Hiển thị thông tin khóa đã quét để xác nhận
                ListTile(
                  leading: Icon(Icons.vpn_key, color: Theme.of(context).primaryColor),
                  title: Text("Khóa: $lockNameFromQR"),
                  subtitle: Text("ID: $lockIdFromQR"),
                ),
                Divider(height: 24),

                const Text(
                  'Nhập mã bí mật được cung cấp bởi người chia sẻ:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: secretCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Mã bí mật',
                    hintText: 'Nhập mã bí mật tại đây',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                  ),
                  keyboardType: TextInputType.text, // Hoặc number nếu mã chỉ là số
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

                CustomButton(
                  text: isLoading ? "Đang xử lý..." : "Xác thực & Thêm Khóa",
                  isLoading: isLoading,
                  onPressed: () async {
                    final secretCode = secretCodeController.text.trim();
                    if (secretCode.isEmpty) {
                      setState(() { errorMessage = 'Vui lòng nhập mã bí mật.'; });
                      return;
                    }

                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });

                    try {
                      // 1. Xác thực mã bí mật với server
                      bool isValidCode = await validateSecretCodeOnServer(secretCode);

                      if (isValidCode) {
                        // 2. Nếu mã hợp lệ, thêm khóa vào Firebase của người nhận
                        bool addedSuccess = await addLockToReceiverFirebase(receiverUserId, scannedLockInfo);

                        if (addedSuccess) {
                          // Thành công! Đóng sheet và thông báo
                          if (context.mounted) Navigator.pop(context); // Đóng BottomSheet
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã thêm khóa "$lockNameFromQR" thành công!')),
                            );
                            // Có thể điều hướng đến màn hình chính hoặc danh sách khóa ở đây
                            // Navigator.pushReplacementNamed(context, '/home');
                          }
                        } else {
                          // Lỗi xảy ra khi thêm vào Firebase (đã được log bên trong hàm)
                          // Hàm addLockToReceiverFirebase nên ném lỗi để bắt ở đây
                          // errorMessage đã được set trong hàm kia nếu cần, hoặc set ở đây
                          setState(() {
                            errorMessage = errorMessage ?? 'Lỗi cập nhật danh sách khóa.';
                          });
                        }

                      } else {
                        // Mã không hợp lệ (errorMessage đã được set trong validateSecretCodeOnServer)
                        setState(() {
                          // Chỉ cần setState để cập nhật errorMessage đã được đặt
                        });
                      }
                    } catch (e) {
                      // Bắt lỗi từ validateSecretCodeOnServer hoặc addLockToReceiverFirebase
                      print("Error in validation/add process: $e");
                      setState(() {
                        errorMessage = e.toString().replaceFirst("Exception: ", ""); // Hiển thị lỗi
                      });
                    } finally {
                      // Đảm bảo isLoading được đặt lại ngay cả khi có lỗi
                      // Kiểm tra mounted trước khi gọi setState
                      if (context.mounted) {
                        setState(() { isLoading = false; });
                      }
                    }
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