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
- Tải thư viện qua PlatformIO: New terminal -> pio lib install "chris--a/Keypad@3.1.1"
                                               pio lib install "fmalpartida/LiquidCrystal@1.5.0"

--------------------------------------------------------------                      
- Khi ấn vào nút A thì relay sẽ tắt -> đèn tắt, sau 5s relay mở -> đèn mở