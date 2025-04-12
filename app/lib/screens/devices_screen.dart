import 'package:flutter/material.dart';
import 'package:app/widgets/custom_appbar.dart';

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
            CustomAppBar(subtitle: 'Quản lý thiết bị'),
            SizedBox(height: 40),
            _buildSmartLockCard(),
            SizedBox(height: 100), 
          ],
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
                  'Mở khóa: 20:30:00 01/01/2023',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}