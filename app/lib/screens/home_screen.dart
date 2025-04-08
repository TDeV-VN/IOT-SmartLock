import 'package:flutter/material.dart';
import 'package:app/widgets/bottom_navigation_bar.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
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
                          color: Color(0xFF0F0F0F),
                        ),
                      ),
                      Text(
                        'Smart Lock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F0F0F),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.login, color: Colors.white),
                    label: Text('Login', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F0F0F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildCategorySelector(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F0F0F),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Expanded(
                child: GridView.count(
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          
          NavBarItem(icon: Icons.home, label: 'Home'),
          NavBarItem(icon: Icons.list_alt, label: 'Order'),
          NavBarItem(icon: Icons.shopping_cart, label: 'My Cart'),
          NavBarItem(icon: Icons.more_horiz, label: 'More'),
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
      margin: EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF0F0F0F) : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade300),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 60,
                  color: Color(0xFF0F0F0F),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  calories,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
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