- Đây là một dự án PlatformIO, để xây dựng nó trong VSCode cần cài extension PlatformIO IDE.
----------------------------------------------------------
- Cài Extension Wokwi Simulator -> F1 -> Wokwi: request a new license
----------------------------------------------------------
- Build dự án: F1 -> PlatformIO: New terminal -> nếu chưa ở trong thư mục esp32 thì "cd esp32" -> nhập lệnh: pio run
--------------------------------------------------------
- Chạy mô phỏng: Double click vào file diagram.json rồi nhấn nút run
--------------------------------------------------------
- Để thay đổi sơ đồ linh kiện: chỉnh sửa sơ đồ trên Wokwi.com sau đó copy nội dung của file diagram.json. Trong VSCode, click phải vào file diagram.json -> Open with... -> Text editor -> dán nội dung đã copy vào.
--------------------------------------------------------------
- Để giao tiếp với trình mô phỏng qua wifi với máy ảo android studio: thay "localhost" bằng "10.0.2.2". Ví dụ: http://localhost:8180 -> http://10.0.2.2:8180

--------------------------------------------------------------                      
- Khi ấn vào nút # thì relay sẽ tắt -> đèn tắt, sau 5s relay mở -> đèn mở

- Khi ấn nút B nó sẽ lưu thông tin vào warning_history

- Khi ấn nút # nó sẽ lưu thông tin vào open_history, chưa thể thêm vào latest_notification
------------------------------------------------------------------

NẠP CODE CHO BOARD Kit Wifi BLE ESP32 NodeMCU-32S CH340 Ai-Thinker:
1. Tải xuống và cài đặt driver: https://www.wch.cn/download/file?id=65
2. Vào file platformio.ini -> đổi thành "board = nodemcu-32s"
3. Build firmware: F1 -> PlatformIO: Build.
3. Nạp code: F1 -> PlatformIO: Upload.