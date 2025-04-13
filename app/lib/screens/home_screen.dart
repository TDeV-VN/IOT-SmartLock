import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants; 
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'devices_screen.dart';
import 'profile_screen.dart';
import 'package:app/widgets/custom_appbar.dart';
import 'package:app/services/fcm_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late TabController _tabController;
  late List<Widget> _screens;
  late FCMService _fcmService;
    // Thêm navigatorKey cho FCMService
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    _fcmService = FCMService(navigatorKey: _navigatorKey); // Khởi tạo FCMService
    
    _screens = [
      _buildHomeContent(),
      DevicesScreen(fcmService: _fcmService), // Truyền FCMService vào DevicesScreen
      ProfileScreen(),
    ];

    _pageController = PageController(initialPage: _selectedIndex);
    _tabController = TabController(length: 3, vsync: this, initialIndex: _selectedIndex);

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          children: _screens,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
              _tabController.animateTo(index);
            });
          },
          physics: const BouncingScrollPhysics(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppBar(subtitle: 'Cho cuộc sống hiện đại'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}