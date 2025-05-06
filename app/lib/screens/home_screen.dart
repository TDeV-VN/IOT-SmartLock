import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants;
import 'package:app/widgets/bottom_navigation_bar.dart';
import '../services/mqtt_handler.dart'; // Đảm bảo import này đúng
import 'change_pin_code.dart';
import 'devices_screen.dart';
import 'profile_screen.dart';
import 'package:app/widgets/custom_appbar.dart';
import 'dart:async'; // Thêm import này cho StreamSubscription

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
  // late List<Widget> _screens; // Sẽ định nghĩa trong build hoặc nơi khác nếu cần

  String? _selectedLockId;
  Map<String, dynamic>? _currentLockData;
  List<Map<String, dynamic>> _locks = [];

  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();

  // Stream Subscriptions để quản lý listeners
  StreamSubscription? _accountLocksSubscription;
  StreamSubscription? _lockDataSubscription;

  @override
  void initState() {
    super.initState();
    _initAccountLocksListener(); // Bắt đầu lắng nghe danh sách locks

    // _screens = [_buildHomeContent(), DevicesScreen(), ProfileScreen()]; // Không thể gọi _buildHomeContent ở đây vì nó phụ thuộc vào state
    _pageController = PageController(initialPage: _selectedIndex);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedIndex,
    )..addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _selectedIndex = _tabController.index);
        _pageController.jumpToPage(_tabController.index); // Đồng bộ PageController
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _accountLocksSubscription?.cancel(); // Hủy listener khi widget bị hủy
    _lockDataSubscription?.cancel();   // Hủy listener khi widget bị hủy
    super.dispose();
  }

  void _initAccountLocksListener() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _accountLocksSubscription?.cancel(); // Hủy listener cũ nếu có
    _accountLocksSubscription =
        _dbRef.child('account/$uid/lock').onValue.listen((event) {
          if (!mounted) return;

          List<Map<String, dynamic>> newLocks = [];
          final data = event.snapshot.value;

          if (data is List) {
            for (var item in data) {
              if (item is Map) {
                final id = item['id']?.toString();
                final name = item['name']?.toString();
                // Chỉ thêm lock nếu có ID hợp lệ
                if (id != null && id.isNotEmpty) {
                  newLocks.add({
                    'id': id,
                    'name': name ?? 'Unnamed Lock', // Cung cấp tên mặc định nếu null
                    'message': item['latest_notification']?['message'] ?? '',
                    'time': item['latest_notification']?['time'] ?? '',
                  });
                }
              }
            }
          }

          String? newPotentialSelectedLockId = _selectedLockId;

          if (newLocks.isEmpty) {
            newPotentialSelectedLockId = null;
          } else {
            // Kiểm tra xem lock đang chọn có còn tồn tại trong danh sách mới không
            bool currentSelectedLockStillExists =
            newLocks.any((lock) => lock['id'] == _selectedLockId);

            if (!currentSelectedLockStillExists || _selectedLockId == null) {
              // Nếu lock cũ không còn, hoặc chưa có lock nào được chọn, chọn lock đầu tiên
              newPotentialSelectedLockId = newLocks.first['id'];
            }
            // Nếu lock cũ vẫn tồn tại, newPotentialSelectedLockId sẽ giữ nguyên giá trị _selectedLockId
          }

          // Chỉ setState nếu có sự thay đổi cần thiết
          bool locksChanged = !_areLocksEqual(_locks, newLocks);
          bool selectedLockIdChanged = _selectedLockId != newPotentialSelectedLockId;

          if (locksChanged || selectedLockIdChanged) {
            setState(() {
              _locks = newLocks;
              if (selectedLockIdChanged) {
                _selectedLockId = newPotentialSelectedLockId;
                _currentLockData = null; // Reset dữ liệu lock hiện tại
                _lockDataSubscription?.cancel(); // Hủy listener của lock cũ

                if (_selectedLockId != null) {
                  _loadLockData(_selectedLockId!); // Tải dữ liệu cho lock mới
                }
              } else if (_selectedLockId == null) {
                // Trường hợp locks rỗng và selectedId đã là null hoặc trở thành null
                _currentLockData = null;
                _lockDataSubscription?.cancel();
              }
            });
          }
        });
  }

  // Hàm trợ giúp để so sánh hai danh sách locks (đơn giản, có thể cải thiện)
  bool _areLocksEqual(List<Map<String, dynamic>> l1, List<Map<String, dynamic>> l2) {
    if (l1.length != l2.length) return false;
    for (int i = 0; i < l1.length; i++) {
      if (l1[i]['id'] != l2[i]['id'] || l1[i]['name'] != l2[i]['name']) {
        return false;
      }
    }
    return true;
  }


  void _loadLockData(String lockId) {
    _lockDataSubscription?.cancel(); // Luôn hủy listener cũ trước khi tạo mới
    _lockDataSubscription =
        _dbRef.child('lock/$lockId').onValue.listen((event) {
          if (!mounted) return;

          // Rất quan trọng: Chỉ cập nhật _currentLockData nếu lockId của listener này
          // vẫn là _selectedLockId hiện tại. Điều này tránh race condition khi
          // người dùng chuyển đổi lock nhanh chóng.
          if (lockId == _selectedLockId) {
            final data = event.snapshot.value;
            setState(() {
              if (data is Map) {
                _currentLockData = Map<String, dynamic>.from(data);
              } else {
                _currentLockData = null; // Dữ liệu lock không hợp lệ hoặc lock đã bị xóa
              }
            });
          }
        });
  }

  void openLock(String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();
    final topic = 'esp32/$lockId';
    mqtt.publishMessage(topic, 'Open');
  }

  void offBuzzer(String lockId) async {
    final mqtt = MQTTService();
    await mqtt.connect();
    final topic = 'esp32/$lockId';
    mqtt.publishMessage(topic, 'TurnOffBuzzer');

    FirebaseDatabase.instance
        .ref('lock/$lockId/pin_code_disable') // Sử dụng lockId thay vì _selectedLockId
        .remove();
  }

  void _toggleLock() {
    if (_currentLockData == null || _selectedLockId == null) return;
    openLock(_selectedLockId!);
  }

  @override
  Widget build(BuildContext context) {
    // Định nghĩa _screens ở đây để _buildHomeContent được gọi mỗi khi build
    // _screens = [_buildHomeContent(), DevicesScreen(), ProfileScreen()]; // Di chuyển vào PageView children

    return Scaffold(
      backgroundColor: constants.screenBackground,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (i) {
            if (mounted) {
              setState(() {
                _selectedIndex = i;
                _tabController.animateTo(i);
              });
            }
          },
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            _buildHomeContent(), // Trang Home
            DevicesScreen(),      // Trang Devices
            ProfileScreen()       // Trang Profile
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) {
          if (mounted) {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            // setState(() => _selectedIndex = i); // onPageChanged sẽ xử lý việc này
          }
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
            Padding( // Thêm Padding cho dễ nhìn
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'Không có khóa nào được kết nối.\nVui lòng thêm thiết bị.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          else if (_selectedLockId == null) // Trường hợp _locks không rỗng nhưng chưa chọn được lock (ít xảy ra với logic mới)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'Vui lòng chọn một khóa từ danh sách.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          else if (_currentLockData == null && _selectedLockId != null) // Đang tải dữ liệu cho lock đã chọn
              const Center(child: CircularProgressIndicator())
            else
              _buildLockStatus(), // Hiển thị trạng thái khóa
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
          value: _selectedLockId, // Sẽ là null nếu _locks rỗng hoặc không có lock nào hợp lệ
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: constants.primary1,
          ),
          hint: _locks.isEmpty ? const Center(child: Text("Không có khóa")) : null, // Hint khi không có khóa
          items: _locks.map<DropdownMenuItem<String>>((lock) {
            // Đã đảm bảo id và name là String và không null trong _initAccountLocksListener
            return DropdownMenuItem<String>(
              value: lock['id'],
              child: Center(child: Text(lock['name']!)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value != _selectedLockId) { // Chỉ xử lý nếu giá trị thực sự thay đổi
              if (!mounted) return;
              setState(() {
                _selectedLockId = value;
                _currentLockData = null; // Reset để hiển thị loading
              });
              _lockDataSubscription?.cancel(); // Hủy listener của lock cũ
              _loadLockData(value);          // Tải dữ liệu cho lock mới
            }
          },
        ),
      ),
    );
  }

  Widget _buildLockStatus() {
    // _currentLockData không thể null ở đây do kiểm tra ở _buildHomeContent
    final isLocked = _currentLockData!['locking_status'] as bool? ?? true;
    final hasDisabledPin = _currentLockData!.containsKey('pin_code_disable');

    return Column(
      children: [
        if (hasDisabledPin)
          _buildPinCodeWarning()
        else if (isLocked) // Chỉ hiển thị nút toggle khi không có cảnh báo pin
          LockButton(isLocked: isLocked, onToggle: _toggleLock)
        else // Đã mở, không cần onToggle phức tạp, hoặc có thể là nút để khóa lại
          LockButton(isLocked: isLocked, onToggle: _toggleLock), // Cho phép nhấn để khóa lại
      ],
    );
  }

  Widget _buildPinCodeWarning() {
    if (_selectedLockId == null || _currentLockData == null || !_currentLockData!.containsKey('pin_code_disable')) {
      return const SizedBox.shrink(); // Không hiển thị nếu không có dữ liệu cần thiết
    }
    final rawPinData = _currentLockData!['pin_code_disable'];
    if (rawPinData == null || rawPinData is! Map) {
      return const SizedBox.shrink(); // Dữ liệu không hợp lệ
    }

    final pinData = (rawPinData as Map).map(
          (key, value) => MapEntry(key.toString(), value),
    );
    final expirationString = pinData['expiration_time']?.toString();
    if (expirationString == null) return const SizedBox.shrink();

    final expiration = int.tryParse(expirationString);
    if (expiration == null) return const SizedBox.shrink();


    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
            (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final remaining =
            expiration - DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (remaining <= 0) {
          // Sử dụng addPostFrameCallback để tránh setState trong khi build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedLockId != null) {
              FirebaseDatabase.instance
                  .ref('lock/$_selectedLockId/pin_code_disable')
                  .remove();
              // Không cần setState ở đây vì listener của _loadLockData sẽ cập nhật UI
            }
          });
          return const SizedBox.shrink(); // Hoặc một UI báo hết thời gian chờ
        }

        final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
        final seconds = (remaining % 60).toString().padLeft(2, '0');
        final formattedTime = "$minutes:$seconds";

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Cảnh báo", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Phát hiện truy cập trái phép", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              const Text("Vô hiệu hóa thao tác mở\nbằng mã khóa trong", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text(formattedTime, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_selectedLockId != null) {
                    showChangePinCodeBottomSheet(context, _selectedLockId!);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: const Text("Đổi mã khóa", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (_selectedLockId != null) {
                    offBuzzer(_selectedLockId!); // Đã sửa offBuzzer để dùng lockId truyền vào
                  }
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
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onToggle(); // Gọi onToggle khi nhả chuột
          },
          onTapCancel: () => setState(() => _isPressed = false),
          // onTap: widget.onToggle, // Đã chuyển vào onTapUp
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isLocked ? constants.green : constants.blackshade,
              boxShadow: widget.isLocked
                  ? (_isPressed
                  ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                  : [const BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(4, 6))])
                  : null, // Không có shadow khi mở
            ),
            child: Center(
              child: Image.asset(
                widget.isLocked ? 'assets/images/locked.png' : 'assets/images/opened.png',
                width: 70, height: 70,
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