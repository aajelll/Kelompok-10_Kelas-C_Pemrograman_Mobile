import 'package:flutter/material.dart';

import '../core/widgets/floating_nav_bar.dart';
import 'progress/screens/progress_screen.dart';
import 'vocabulary/screens/home_screen.dart';
import 'vocabulary/screens/search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    SearchScreen(),
    ProgressScreen(),
  ];

  static const _items = <FloatingNavItem>[
    FloatingNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    FloatingNavItem(
      icon: Icons.search_rounded,
      selectedIcon: Icons.search_rounded,
      label: 'Cari',
    ),
    FloatingNavItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Progres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}