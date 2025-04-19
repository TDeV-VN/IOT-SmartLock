import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants; // Thêm alias 'constants'
import 'package:app/constant.dart'
as constants; // Sử dụng alias để tránh xung đột
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'devices_screen.dart';
import 'profile_screen.dart';
import 'package:app/widgets/custom_appbar.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); // Thêm const constructor

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late TabController _tabController;
  late List<Widget> _screens;
  // Thêm các state
  String? _selectedLockId;
  Map<String, dynamic>? _currentLockData;
  List<Map<String, dynamic>> _locks = [];
  final auth = FirebaseAuth.instance;
  final database = FirebaseDatabase.instance.ref();

// Hàm fetch dữ liệu từ Firebase
  void _fetchLocks() {
    final uuid = auth.currentUser?.uid;
    if (uuid == null) return;

    final userLocksRef = database.child('account/$uuid/lock');

    userLocksRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is List) {
        List<Map<String, dynamic>> updatedLocks = [];
        for (var item in data) {
          if (item != null && item is Map) {
            updatedLocks.add({
              'id': item['id'],
              'name': item['name'],
              'message': item['latest_notification']?['message'] ?? '',
              'time': item['latest_notification']?['time'] ?? '',
            });
          }
        }

        setState(() {
          _locks = updatedLocks;
          //test
          print('Locks: $_locks');
          if (_selectedLockId == null && _locks.isNotEmpty) {
            _selectedLockId = _locks.first['id'];
            _loadLockData(_selectedLockId!);
          }
        });
      } else {
        setState(() => _locks = []); // Xử lý trường hợp data null
      }
    });
  }

  void _loadLockData(String lockId) {
    FirebaseDatabase.instance.ref('lock/$lockId').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _currentLockData = (data as Map).map(
                (key, value) => MapEntry(key.toString(), value),
          );
        });
      }
    });
  }

// Widget Dropdown
  Widget _buildLockDropdown() {
    return Container(
      margin: const EdgeInsets.only(left: 30, right: 30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white, // <-- Nền trắng hoàn toàn
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: constants.primary1, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: Center(
          child: DropdownButton<String>(
            value: _selectedLockId,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: constants.primary1),
            alignment: Alignment.center,
            borderRadius: BorderRadius.circular(16),
            style: const TextStyle(fontSize: 16, color: Colors.black),
            items: _locks.map((lock) {
              return DropdownMenuItem<String>(
                value: lock['id'],
                child: Center(
                  child: Text(
                    lock['name'],
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLockId = value);
                _loadLockData(value);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLockStatus() {
    if (_currentLockData == null) return CircularProgressIndicator();

    final isLocked = _currentLockData!['locking_status'] ?? true;
    final hasDisabledPin = _currentLockData!.containsKey('pin_code_disable');

    return Column(
      children: [
        LockButton(),
        const SizedBox(height: 12),
        if (hasDisabledPin) _buildPinCodeWarning(),
      ],
    );
  }

  void _toggleLock() {
    FirebaseDatabase.instance.ref('lock/$_selectedLockId/locking_status')
        .set(!(_currentLockData!['locking_status'] ?? true));
  }

  @override
  @override
  void initState() {
    super.initState();
    _fetchLocks();
    _screens = [
      Container(), // placeholder tạm, chỉ để không lỗi null
      DevicesScreen(),
      ProfileScreen(),
    ];


    _pageController = PageController(initialPage: _selectedIndex);
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: _selectedIndex);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constants.screenBackground,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
              _tabController.animateTo(index);
            });
          },
          physics: const BouncingScrollPhysics(),
          children: [
            _buildHomeContent(),
            DevicesScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          NavBarItem(icon: Icons.home, label: 'Trang Chủ'),
          NavBarItem(icon: Icons.devices, label: 'Thiết Bị'),
          NavBarItem(icon: Icons.person, label: 'Tài Khoản'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const CustomAppBar(subtitle: 'Cho cuộc sống hiện đại'),
            ],
          ),
          const SizedBox(height: 40),
          _buildLockDropdown(),
          const SizedBox(height: 80),
          _locks.isEmpty
              ? const Text('Không có khóa nào')
              : _buildLockStatus(),
        ],
      ),
    );
  }

  Widget _buildPinCodeWarning() {
    final rawPinData = _currentLockData!['pin_code_disable'];
    final pinData = (rawPinData as Map).map(
          (key, value) => MapEntry(key.toString(), value),
    );
    final expiration = int.parse(pinData['expiration_time'].toString());

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final remaining = expiration - DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (remaining <= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseDatabase.instance.ref('lock/$_selectedLockId/pin_code_disable')
                .remove();
          });
          return SizedBox.shrink();
        }

        final hours = remaining ~/ 3600;
        final minutes = (remaining % 3600) ~/ 60;
        final seconds = remaining % 60;

        // Sửa ở đây: Thay Alert bằng Container/Card
        return Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            children: [
              Text(
                "Cảnh báo: Mã khóa tạm thời đã vô hiệu!",
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Thời gian còn lại: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                style: TextStyle(color: Colors.orange[800]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LockButton extends StatefulWidget {
  @override
  _LockButtonState createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton> {
  bool isLocked = true;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: () {
            setState(() {
              isLocked = !isLocked;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked ? constants.green : constants.blackshade,
              boxShadow: isLocked
                  ? (isPressed
                  ? [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(4, 6),
                ),
              ])
                  : null,
            ),
            child: Center(
              child: Image.asset(
                isLocked ? 'assets/images/locked.png' : 'assets/images/opened.png',
                width: 70,
                height: 70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          isLocked ? 'Đã khóa' : 'Đã mở khóa',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF000000),
          ),
        ),
      ],
    );
  }
}
