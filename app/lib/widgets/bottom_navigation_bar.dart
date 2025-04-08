import 'package:flutter/material.dart';

class NavBarItem {
  final IconData icon;
  final String label;

  NavBarItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;
  
  final Color backgroundColor;
  final Color navBarColor;
  final Color iconColor;
  final double iconSize;
  final double height;

  CustomBottomNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.backgroundColor = Colors.white, 
    this.navBarColor = Colors.black,     
    this.iconColor = Colors.white,      
    this.iconSize = 22.0,
    this.height = 75.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: navBarColor, 
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            return _buildNavItem(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = selectedIndex == index;
    
    return InkWell(
      onTap: () => onItemSelected(index),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(10),
        child: Icon(
          items[index].icon,
          color: iconColor, 
          size: iconSize,
        ),
      ),
    );
  }
}