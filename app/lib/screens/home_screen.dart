import 'package:flutter/material.dart';
import 'package:app/constant.dart'
    as constants; // Sử dụng alias để tránh xung đột
import 'package:app/widgets/bottom_navigation_bar.dart';
import 'devices_screen.dart';
import 'profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildHomeContent(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: constants.grayshade, // Sử dụng màu từ constants
                    ),
                  ),
                  Text(
                    'Smart Lock',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: constants.grayshade,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.logout, color: constants.whiteshade),
                label: Text(
                  'Đăng xuất',
                  style: TextStyle(color: constants.whiteshade),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: constants.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCategorySelector(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: constants.grayshade,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: constants.grayshade.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap:
                true, // Để GridView hoạt động trong SingleChildScrollView
            physics:
                const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của GridView
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _buildFeatureCard(
                icon: Icons.bluetooth,
                title: 'Bluetooth Unlock',
                calories: '0 Cal',
                price: '\$0.00',
                color: Colors.blue[100]!,
              ),
              _buildFeatureCard(
                icon: Icons.nfc,
                title: 'NFC Access',
                calories: '0 Cal',
                price: '\$0.00',
                color: Colors.orange[100]!,
              ),
              _buildFeatureCard(
                icon: Icons.history,
                title: 'Access Log',
                calories: '0 Cal',
                price: '\$0.00',
                color: Colors.yellow[100]!,
              ),
              _buildFeatureCard(
                icon: Icons.people,
                title: 'User Management',
                calories: '0 Cal',
                price: '\$0.00',
                color: Colors.pink[100]!,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryButton('Access', true),
          _buildCategoryButton('Security', false),
          _buildCategoryButton('Settings', false),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? constants.blue : constants.whiteshade,
          foregroundColor:
              isSelected ? constants.whiteshade : constants.grayshade,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: constants.grayshade.withOpacity(0.3)),
          ),
          elevation: 0,
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String calories,
    required String price,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: constants.whiteshade,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: constants.grayshade.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 60,
                  color: constants.grayshade,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  calories,
                  style: TextStyle(
                    color: constants.grayshade,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.add,
                        color: constants.whiteshade,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
