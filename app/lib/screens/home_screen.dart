import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants;
import 'package:app/widgets/bottom_navigation_bar.dart';
import '../services/mqtt_handler.dart';
import 'change_pin_code.dart';
import 'devices_screen.dart';
import 'profile_screen.dart';
import 'package:app/widgets/custom_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late TabController _tabController;
  late List<Widget> _screens;

  String? _selectedLockId;
  Map<String, dynamic>? _currentLockData;
  List<Map<String, dynamic>> _locks = [];

  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _fetchLocks();

    _screens = [Container(), DevicesScreen(), ProfileScreen()];
    _pageController = PageController(initialPage: _selectedIndex);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedIndex,
    )..addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 1) Lấy danh sách lock của user
  void _fetchLocks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _dbRef.child('account/$uid/lock').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is List) {
        final updated = <Map<String, dynamic>>[];
        for (var item in data) {
          if (item is Map) {
            updated.add({
              'id': item['id'],
              'name': item['name'],
              'message': item['latest_notification']?['message'] ?? '',
              'time': item['latest_notification']?['time'] ?? '',
            });
          }
        }
        setState(() {
          _locks = updated;
          if (_selectedLockId == null && _locks.isNotEmpty) {
            _selectedLockId = _locks.first['id'];
            _loadLockData(_selectedLockId!);
          }
        });
      } else {
        setState(() => _locks = []);
      }
    });
  }

  // 2) Lắng nghe chi tiết của lock được chọn
  void _loadLockData(String lockId) {
    _dbRef.child('lock/$lockId').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          _currentLockData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  void openLock(String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();
    final topic = 'esp32/$lockId';
    final client = mqtt.client;
    mqtt.publishMessage(topic, 'Open');

    // final mqtt = MQTTService();
    // await mqtt.connect();
    // final topic = 'esp32/$lockId';
    // mqtt.publishMessage(topic, '', retain: true);
  }

  void offBuzzer(String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();
    final topic = 'esp32/$lockId';
    mqtt.publishMessage(topic, 'TurnOffBuzzer');

    // Xóa dữ liệu pin_code_disable
    FirebaseDatabase.instance
        .ref('lock/$_selectedLockId/pin_code_disable')
        .remove();
  }

  void _toggleLock() {
    if (_currentLockData == null) return;
    openLock(_selectedLockId!);
    // UI sẽ tự cập nhật khi listener onValue nhận về giá trị mới.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constants.screenBackground,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) {
            setState(() {
              _selectedIndex = i;
              _tabController.animateTo(i);
            });
          },
          physics: const BouncingScrollPhysics(),
          children: [_buildHomeContent(), DevicesScreen(), ProfileScreen()],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) {
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() => _selectedIndex = i);
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [CustomAppBar(subtitle: 'Cho cuộc sống hiện đại')],
          ),
          const SizedBox(height: 40),
          _buildLockDropdown(),
          const SizedBox(height: 80),
          if (_locks.isEmpty)
            const Text('Không có khóa nào')
          else
            _buildLockStatus(),
        ],
      ),
    );
  }

  Widget _buildLockDropdown() {
    return Container(
      margin: const EdgeInsets.only(left: 30, right: 30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: constants.primary1, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLockId,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: constants.primary1,
          ),
          items:
              _locks.map<DropdownMenuItem<String>>((lock) {
                // Ép kiểu id và name về String
                final id = lock['id'].toString();
                final name = lock['name'].toString();
                return DropdownMenuItem<String>(
                  value: id,
                  child: Center(child: Text(name)),
                );
              }).toList(), // giờ đây là List<DropdownMenuItem<String>>
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedLockId = value);
              _loadLockData(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLockStatus() {
    if (_currentLockData == null) {
      return const CircularProgressIndicator();
    }

    final isLocked = _currentLockData!['locking_status'] as bool? ?? true;
    final hasDisabledPin = _currentLockData!.containsKey('pin_code_disable');

    return Column(
      children: [
        if (hasDisabledPin)
          _buildPinCodeWarning()
        else if (isLocked)
          LockButton(isLocked: isLocked, onToggle: _toggleLock)
        else
          LockButton(isLocked: isLocked, onToggle: () {}),
      ],
    );
  }

  Widget _buildPinCodeWarning() {
    final rawPinData = _currentLockData!['pin_code_disable'];
    final pinData = (rawPinData as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final expiration = int.parse(pinData['expiration_time'].toString());

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final remaining =
            expiration - DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (remaining <= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseDatabase.instance
                .ref('lock/$_selectedLockId/pin_code_disable')
                .remove();
          });
          return const SizedBox.shrink();
        }

        final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
        final seconds = (remaining % 60).toString().padLeft(2, '0');
        final formattedTime = "$minutes:$seconds";

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cảnh báo",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Phát hiện truy cập trái phép",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vô hiệu hóa thao tác mở\nbằng mã khóa trong",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  showChangePinCodeBottomSheet(context, _selectedLockId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "Đổi mã khóa",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // xoá dữ liệu ở khóa thông qua mqtt
                  offBuzzer(_selectedLockId!);
                },
                child: const Text("Bỏ qua", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget con chỉ lo render và gọi callback
class LockButton extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onToggle;

  const LockButton({Key? key, required this.isLocked, required this.onToggle})
    : super(key: key);

  @override
  _LockButtonState createState() => _LockButtonState();
}

class _LockButtonState extends State<LockButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isLocked ? constants.green : constants.blackshade,
              boxShadow:
                  widget.isLocked
                      ? (_isPressed
                          ? [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ]
                          : [
                            const BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(4, 6),
                            ),
                          ])
                      : null,
            ),
            child: Center(
              child: Image.asset(
                widget.isLocked
                    ? 'assets/images/locked.png'
                    : 'assets/images/opened.png',
                width: 70,
                height: 70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          widget.isLocked ? 'Đã khóa' : 'Đã mở khóa',
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }
}
