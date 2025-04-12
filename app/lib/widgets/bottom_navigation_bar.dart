import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants; // Thêm alias 'constants'

class NavBarItem {
  final IconData icon;
  final String label;

  NavBarItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;

  final Color backgroundColor = constants.whiteshade;
  final Color navBarColor = constants.primary1;
  final Color selectedItemColor = Colors.white;
  final Color unselectedItemColor = Colors.grey;
  final double iconSize = 20.0;
  final double height = 70.0;

  CustomBottomNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items
  });

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  Map<int, int> _tapCount = {};
  Map<int, DateTime> _lastTapTime = {};
  
  final Duration _resetDuration = Duration(seconds: 3);
  final int _tapThreshold = 3;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.items.length; i++) {
      _tapCount[i] = 0;
    }
  }

  void _handleTap(int index) {
    final now = DateTime.now();
    
    if (index == widget.selectedIndex) {
      if (_lastTapTime.containsKey(index) && 
          now.difference(_lastTapTime[index]!) > _resetDuration) {
        _tapCount[index] = 1;  
      } else {
        _tapCount[index] = (_tapCount[index] ?? 0) + 1;  
      }
      
      _lastTapTime[index] = now;
      
      if (_tapCount[index]! >= _tapThreshold) {
        _showTapNotification(index);
        _tapCount[index] = 0;  
      }
    } else {
      _tapCount[index] = 1;
      _lastTapTime[index] = now;
      
      widget.onItemSelected(index);
    }
  }
  
  void _showTapNotification(int index) {
    final String tabName = widget.items[index].label;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bạn đã nhấn vào tab "$tabName" nhiều lần'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: widget.navBarColor, 
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.items.length, (index) {
            return _buildNavItem(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = widget.selectedIndex == index;
    
    return InkWell(
      onTap: () => _handleTap(index),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.items[index].icon,
              color: isSelected ? widget.selectedItemColor : widget.unselectedItemColor, 
              size: widget.iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              widget.items[index].label,
              style: TextStyle(
                color: isSelected ? widget.selectedItemColor : widget.unselectedItemColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}