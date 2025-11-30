# 📌 BẮT BUỘC

- Đây là một dự án **PlatformIO**, để xây dựng nó trong **VSCode** cần cài đặt extension **PlatformIO IDE**.

---

# 🚀 CHẠY TRÊN MÔ PHỎNG WOKWI

1. Cài Extension **"Wokwi Simulator"**  
   ➜ Nhấn `F1` → chọn `Wokwi: request a new license`.

2. Build dự án:  
   ➜ Nhấn `F1` → `PlatformIO: New terminal`  
   ➜ Nếu chưa ở trong thư mục `esp32` thì chạy:

   ```bash
   cd esp32
   ```

   ➜ Sau đó chạy lệnh:

   ```bash
   pio run -e wokwi
   ```

3. Chạy mô phỏng:  
   ➜ Double click vào file `diagram.json` rồi nhấn nút **Run**.

4. Điều khiển khóa qua ứng dụng **Flutter** với tài khoản:
   ```
   Email: wokwi@simulator.com
   Mật khẩu: 12345678
   ```
   (hoặc tài khoản đã có liên kết với khóa có ID `WokwiBoard01`)

---

# 🔌 NẠP CODE CHO BOARD THẬT

**(Kit Wifi BLE ESP32 NodeMCU-32S CH340 Ai-Thinker)**

1. Tải và cài đặt driver:  
   [https://www.wch.cn/download/file?id=65](https://www.wch.cn/download/file?id=65)

2. Nạp code:  
   ➜ Chạy lệnh `pio run -e nodemcu-32s -t upload`

---

# 🛠️ CÁCH THAY ĐỔI SƠ ĐỒ LINH KIỆN TRONG MÔ PHỎNG WOKWI

- Chỉnh sửa sơ đồ trên [https://wokwi.com](https://wokwi.com)
- Copy nội dung file `diagram.json`
- Trong VSCode:
  - Click phải vào `diagram.json` → chọn `Open with...` → `Text editor`
  - Dán nội dung đã copy vào.

---

# 🛠️ Cách phát hành một phiên bản Firmware mới

- Tạo một tag mới với tag name bắt đầu bằng "v"
- Push tag lên nhánh main
- Sau một thời gian ngắn, thông báo về phiên bản mới sẽ được gửi đến người dùng và sẵn sàng để được tải về.
- Có thể xem qua các phiên bản đã phát hành [tại đây](https://github.com/TDeV-VN/IOT-SmartLock-Firmware/tree/firmware)
- Ví dụ:
  `git tag v1.2.3`
  `git push origin v1.2.3`

---

# ℹ️ MỘT SỐ THÔNG TIN KHÁC

- Tài khoản truy cập **Firebase**, **HiveMQ**, **Render.com**:
  ```
  Email: slocktdtu@gmail.com
  Mật khẩu: #12345678SLock
  ```
- Trong trường hợp hỏng dữ liệu ở **Firebase Realtime Database**:
  ```
  - Xóa toàn bộ dữ liệu bằng **Firbase console**
  - Nhập lại dữ liệu mới từ file `BaseData.json`
  ```
