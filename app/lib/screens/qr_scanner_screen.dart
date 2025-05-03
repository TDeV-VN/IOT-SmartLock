import 'dart:convert';
import 'dart:typed_data'; // Để dùng Uint8List
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/add_lock_utils.dart'; // GIẢ SỬ ĐƯỜNG DẪN NÀY ĐÚNG

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Sử dụng controller của mobile_scanner
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasCameraPermission = false;

  Widget _buildMobileScannerErrorWidget(BuildContext context, MobileScannerException? error) {
    // In lỗi ra console để debug
    if (error != null) {
      print("MobileScanner Error: Code: ${error.errorCode.name}");
    } else {
      print("MobileScanner Error: Unknown error occurred.");
    }

    // Trả về một Widget để hiển thị lỗi cho người dùng
    return Center(
        child: Container( // Thêm container để tạo nền và padding
          padding: const EdgeInsets.all(16.0),
          color: Colors.black.withOpacity(0.7), // Nền mờ để dễ đọc chữ đỏ
          child: Text(
            error != null
                ? 'Lỗi camera:\n${error.errorCode.name}\n)' // Hiển thị cả mã lỗi và message
                : 'Lỗi camera không xác định',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        )
    );
  }

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    // Quan trọng: giải phóng controller khi không cần nữa
    _controller.dispose();
    super.dispose();
  }

  // Hàm yêu cầu quyền camera
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied || status.isRestricted) {
      // Nếu chưa được cấp hoặc bị từ chối/hạn chế, yêu cầu quyền
      status = await Permission.camera.request();
    }

    // Kiểm tra widget còn tồn tại trước khi gọi setState
    if (mounted) {
      setState(() {
        _hasCameraPermission = status.isGranted;
      });
      // Nếu bị từ chối vĩnh viễn, hiển thị dialog hướng dẫn mở cài đặt
      if (!status.isGranted && status.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog();
      } else if (!status.isGranted) {
        print("Camera permission denied (not permanently).");
        // Có thể hiển thị SnackBar hoặc thông báo khác ở đây
      }
    }
  }

  // Hiển thị dialog khi quyền bị từ chối vĩnh viễn
  void _showPermissionPermanentlyDeniedDialog() {
    // Kiểm tra mounted trước khi hiển thị dialog để tránh lỗi
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Cần quyền Camera"),
        content: const Text(
            "Để quét mã QR, ứng dụng cần quyền truy cập Camera.\n\nVui lòng vào Cài đặt ứng dụng và cấp quyền Camera."),
        actions: <Widget>[
          TextButton(
            child: const Text("Đóng"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Mở Cài đặt"),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Mở cài đặt ứng dụng
            },
          ),
        ],
      ),
    );
  }

  // Hàm xử lý khi quét được mã
  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_isProcessing || !mounted) return; // Thoát nếu đang xử lý hoặc widget đã bị hủy

    final Barcode? barcode = capture.barcodes.firstOrNull;

    if (barcode != null && barcode.rawValue != null) {
      final String rawValue = barcode.rawValue!;
      print("QR Code Scanned: $rawValue");

      // Dừng camera và đánh dấu đang xử lý
      _controller.stop();
      setState(() { _isProcessing = true; });

      // Giải mã JSON và xử lý
      try {
        final Map<String, dynamic> decodedData = jsonDecode(rawValue);

        // Kiểm tra key 'id' tồn tại và không null
        if (decodedData['id'] != null && (decodedData['id'] is String) && (decodedData['id'] as String).isNotEmpty) {
          print("Decoded QR Data: $decodedData");

          // Gọi hàm hiển thị bottom sheet từ file utils
          // Truyền context của màn hình hiện tại và dữ liệu đã giải mã
          showValidateAndAddLockBottomSheet(context, decodedData);

          // Sau khi bottom sheet đóng, ta muốn camera dừng lại hoặc điều hướng đi
          // Không cần restart camera ở đây nữa trừ khi bottom sheet bị hủy
          // Nếu muốn quét lại sau khi đóng bottom sheet, cần logic phức tạp hơn
          // Tạm thời giả định sau khi gọi bottom sheet là xong việc quét

        } else {
          // Dữ liệu QR không hợp lệ
          print("Invalid QR data: 'id' key is missing, null, not a string, or empty.");
          _showErrorAndRestartScan("Mã QR không chứa thông tin khóa hợp lệ.");
        }
      } catch (e) {
        // Lỗi giải mã JSON
        print("Error decoding QR JSON: $e");
        _showErrorAndRestartScan("Mã QR không đúng định dạng dữ liệu.");
      }
      // Không reset _isProcessing ở đây nếu muốn dừng sau khi quét thành công
    }
  }

  // Hàm hiển thị lỗi và khởi động lại camera để quét tiếp
  void _showErrorAndRestartScan(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3), // Tăng thời gian hiển thị lỗi
        ),
      );
      // Khởi động lại camera nếu chưa bị hủy
      _controller.start();
      setState(() {
        _isProcessing = false; // Cho phép xử lý lại
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR Khóa'),
        actions: [
          // // Nút bật/tắt đèn flash
          // ValueListenableBuilder<TorchState>(
          //   valueListenable: _controller.torchState,
          //   builder: (context, state, child) {
          //     if (state == TorchState.unavailable) {
          //       return const SizedBox.shrink();
          //     }
          //     final icon = state == TorchState.on ? Icons.flash_on : Icons.flash_off;
          //     return IconButton(
          //       icon: Icon(icon),
          //       onPressed: () => _controller.toggleTorch(),
          //     );
          //   },
          // ),
          // Nút chuyển camera
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            tooltip: 'Chuyển Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: _hasCameraPermission
          ? Stack(
        alignment: Alignment.center, // Căn giữa các thành phần trong Stack
        children: [
          // Lớp camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeDetection,
            // Fit camera preview vào toàn bộ không gian có sẵn
            fit: BoxFit.cover,

            // --- ĐẢM BẢO CHỮ KÝ HÀM NHƯ SAU ---
            errorBuilder: _buildMobileScannerErrorWidget,
          ), // Kết thúc MobileScanner
          // Lớp vẽ khung quét (overlay)
          Container(
            width: MediaQuery.of(context).size.width * 0.7, // Chiều rộng khung = 70% màn hình
            height: MediaQuery.of(context).size.width * 0.7, // Chiều cao khung = chiều rộng
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green.withOpacity(0.8), // Màu khung rõ hơn
                width: 3, // Độ dày đường viền
              ),
              borderRadius: BorderRadius.circular(12), // Bo góc
            ),
          ),
          // Lớp hiển thị thông báo hướng dẫn
          Positioned( // Đặt vị trí cố định ở dưới
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // Nền mờ
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Đặt mã QR vào trong khung để quét',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Hiển thị loading khi đang xử lý
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7), // Tăng độ mờ
              child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text("Đang xử lý mã QR...", style: TextStyle(color: Colors.white, fontSize: 16))
                    ],
                  )
              ),
            )
        ],
      )
          : Center( // Hiển thị nếu chưa cấp quyền
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Ứng dụng cần quyền truy cập Camera\nđể quét mã QR.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Cấp quyền Camera"),
              onPressed: _requestCameraPermission,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            )
          ],
        ),
      ),
    );
  }
}