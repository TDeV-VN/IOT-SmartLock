import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
// import 'package:qr_flutter/qr_flutter.dart'; // Không cần cho sheet này
import '../widgets/custom_button.dart'; // Import CustomButton

// --- HÀM XÁC THỰC MÃ BÍ MẬT TRÊN SERVER (Đã sửa lỗi xử lý Exception) ---
Future<bool> validateSecretCodeOnServer(String secretCode) async {
  const String backendBaseUrl = "https://iot-smartlock-firmware.onrender.com";

  // Tạo URL với query parameter
  final queryParams = {'code': secretCode};
  final url = Uri.parse('$backendBaseUrl/validate-secret-code').replace(queryParameters: queryParams);

  try {
    print('Validating secret code via URL: $url');

    // Gửi POST request không có body/header đặc biệt
    final response = await http.post(
      url,
    ).timeout(const Duration(seconds: 60));

    print('Validate Secret Code Response: ${response.statusCode} - ${response.body}');

    // Xử lý phản hồi từ Server
    if (response.statusCode == 200) {
      try {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('valid') && responseData['valid'] == true) {
          print("Secret code is valid.");
          return true;
        } else {
          // Server trả về valid=false hoặc không có key 'valid'
          throw Exception("Mã bí mật không hợp lệ hoặc đã hết hạn.");
        }
      } catch (e) {
        // Chỉ ném lỗi này nếu JSON không parse được
        if (e is FormatException) {
          print("Error parsing successful response JSON: $e");
          throw Exception("Phản hồi từ server không hợp lệ.");
        }
        rethrow; // Ném lại lỗi ban đầu (nếu không phải lỗi parse JSON)
      }
    } else if (response.statusCode == 404) {
      // Lỗi 404
      final errorMessage = "Mã bí mật không tồn tại hoặc đã hết hạn (Code 404).";
      print("Secret code not found or expired (404).");
      throw Exception(errorMessage);
    } else {
      // Các lỗi khác (400, 422, 5xx, ...)
      String detailMessage = 'Lỗi không xác định từ server.'; // Mặc định
      try {
        // Cố gắng parse lỗi chi tiết từ body JSON (thường là từ FastAPI)
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          if (errorData['detail'] is List && errorData['detail'].isNotEmpty) {
            // Lấy lỗi đầu tiên nếu detail là list
            var firstError = errorData['detail'][0];
            if(firstError is Map && firstError.containsKey('msg')){
              detailMessage = firstError['msg'] ?? detailMessage;
            } else {
              detailMessage = errorData['detail'].toString(); // Chuyển list thành chuỗi nếu không có 'msg'
            }
          } else if (errorData['detail'] is String) {
            // Nếu detail là chuỗi
            detailMessage = errorData['detail'];
          }
        }
      } catch (_) {
        // Không parse được JSON lỗi, dùng mã lỗi HTTP làm thông báo
        detailMessage = 'Lỗi ${response.statusCode} khi xác thực mã.';
      }
      final errorMessage = detailMessage;
      print("Validation failed with status ${response.statusCode}. Detail: $errorMessage");
      throw Exception(errorMessage); // Ném lỗi cụ thể
    }
  } on TimeoutException catch (_) {
    // Bắt lỗi Timeout riêng
    print('Validate secret code request timed out.');
    throw Exception('Hết thời gian chờ phản hồi từ máy chủ.');
  } catch (e) {
    // Bắt các lỗi khác (ví dụ: lỗi mạng DNS, SocketException)
    // và các Exception đã được ném từ các khối trên
    print('Error caught in validateSecretCodeOnServer: $e');

    // Kiểm tra xem lỗi đã có message chưa, nếu chưa thì cung cấp message chung
    String errorMessageToShow;
    if (e is Exception) {
      // Cố gắng lấy message từ Exception
      var message = e.toString();
      // Loại bỏ tiền tố "Exception: " nếu có
      if (message.startsWith("Exception: ")) {
        message = message.substring("Exception: ".length);
      }
      errorMessageToShow = message.trim().isNotEmpty ? message : 'Đã xảy ra lỗi không mong muốn.';
    } else {
      errorMessageToShow = 'Đã xảy ra lỗi không mong muốn.';
    }

    // Ném lại Exception với thông báo đã xử lý
    throw Exception(errorMessageToShow);
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
                      String code = lockIdFromQR + secretCode; // Tạo mã bí mật từ ID khóa và mã bí mật
                      bool isValidCode = await validateSecretCodeOnServer(code);

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
                            Navigator.pushNamed(context, '/home');
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
                          errorMessage = errorMessage ?? 'Mã bí mật không hợp lệ.';
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