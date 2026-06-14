import 'package:flutter/material.dart';

import 'screens/coach_chat_screen.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

class HunkApp extends StatelessWidget {
  const HunkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<_AppDestination> _destinations = [
    _AppDestination(
      title: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      screen: HomeScreen(),
    ),
    _AppDestination(
      title: 'Health',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
      screen: HealthScreen(),
    ),
    _AppDestination(
      title: 'Coach',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
      screen: CoachChatScreen(),
    ),
    _AppDestination(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      screen: SettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(destination.title)),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (final destination in _destinations) destination.screen,
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.title,
            ),
        ],
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
