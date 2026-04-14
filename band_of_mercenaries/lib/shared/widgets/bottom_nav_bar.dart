import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Text('🗺', style: TextStyle(fontSize: 22)), label: '이동'),
        BottomNavigationBarItem(icon: Text('⚔', style: TextStyle(fontSize: 22)), label: '파견'),
        BottomNavigationBarItem(icon: Text('🏕', style: TextStyle(fontSize: 22)), label: '홈'),
        BottomNavigationBarItem(icon: Text('👥', style: TextStyle(fontSize: 22)), label: '모집'),
        BottomNavigationBarItem(icon: Text('🏗', style: TextStyle(fontSize: 22)), label: '시설'),
        BottomNavigationBarItem(icon: Text('⚙', style: TextStyle(fontSize: 22)), label: '설정'),
      ],
    );
  }
}
