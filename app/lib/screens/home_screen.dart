import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
    theme: ThemeData(fontFamily: 'Roboto'),
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1), 
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Smart Lock",
          style: TextStyle(color: Colors.white), 
        ),
        backgroundColor: Color(0xFF0F0F0F), 
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, "/login");
            },
            child: Text(
              "Đăng nhập",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white, 
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Chào mừng bạn đến với Smart Lock!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, 
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Giải pháp mở khóa cửa thông minh, tiện lợi và an toàn.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),

              _buildFeatureItem(Icons.lock, "Mở khóa bằng Bluetooth / NFC"),
              _buildFeatureItem(Icons.history, "Xem lịch sử mở khóa"),
              _buildFeatureItem(Icons.people, "Quản lý người dùng"),
              _buildFeatureItem(Icons.vpn_key, "Tùy chỉnh quyền truy cập"),
              _buildFeatureItem(Icons.support_agent, "Hỗ trợ nhiều loại cửa thông minh"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return GestureDetector(
      onTap: () {
      },
      child: Card(
        color: Colors.white, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10, 
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Icon(icon, color: Color(0xFF0F0F0F), size: 30),
          title: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
