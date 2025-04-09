import 'package:flutter/material.dart';

class DevicesScreen extends StatefulWidget {
  @override
  _DevicesScreenState createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _isLockOpen = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'Thiết Bị Của Tôi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F0F0F),
              ),
            ),
            SizedBox(height: 20),
            _buildSearchBar(),
            SizedBox(height: 20),
            Text(
              'Khóa Thông Minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F0F0F),
              ),
            ),
            SizedBox(height: 15),
            _buildSmartLockCard(),
            SizedBox(height: 20),
            Text(
              'Thiết Bị Khác',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F0F0F),
              ),
            ),
            SizedBox(height: 15),
            _buildDeviceCard(
              'Camera An Ninh', 
              'Đang hoạt động', 
              Icons.videocam, 
              Colors.blue[100]!
            ),
            SizedBox(height: 10),
            _buildDeviceCard(
              'Cảm Biến Cửa', 
              'Đang hoạt động', 
              Icons.sensor_door, 
              Colors.green[100]!
            ),
            SizedBox(height: 10),
            _buildDeviceCard(
              'Cảm Biến Chuyển Động', 
              'Đang tắt', 
              Icons.sensors,
              Colors.grey[300]!
            ),
            SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey[600]),
          hintText: 'Tìm kiếm thiết bị',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSmartLockCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _isLockOpen ? Colors.green[100] : Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isLockOpen ? Icons.lock_open : Icons.lock,
              size: 30,
              color: _isLockOpen ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khóa Cửa Chính',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isLockOpen ? 'Đã mở khóa' : 'Đang khóa',
                  style: TextStyle(
                    color: _isLockOpen ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isLockOpen,
            onChanged: (value) {
              setState(() {
                _isLockOpen = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String name, String status, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 25,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: status == 'Đang hoạt động' ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}