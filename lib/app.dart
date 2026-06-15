import 'package:flutter/material.dart';

import 'screens/coach_chat_screen.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ai_chat_service.dart';
import 'services/context_repository.dart';
import 'services/model_listing_service.dart';
import 'services/provider_ai_chat_service.dart';
import 'services/settings_storage.dart';

class HunkApp extends StatelessWidget {
  const HunkApp({
    super.key,
    this.settingsStorage,
    this.modelListingService,
    this.chatService,
    this.contextRepository,
  });

  final SettingsStorage? settingsStorage;
  final ModelListingService? modelListingService;
  final AiChatService? chatService;
  final ContextRepository? contextRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hunk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF237A57)),
        useMaterial3: true,
      ),
      home: AppShell(
        settingsStorage: settingsStorage,
        modelListingService: modelListingService,
        chatService: chatService,
        contextRepository: contextRepository,
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.settingsStorage,
    this.modelListingService,
    this.chatService,
    this.contextRepository,
  });

  final SettingsStorage? settingsStorage;
  final ModelListingService? modelListingService;
  final AiChatService? chatService;
  final ContextRepository? contextRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final SettingsStorage _settingsStorage;
  late final ModelListingService _modelListingService;
  late final AiChatService _chatService;
  late final ContextRepository _contextRepository;

  @override
  void initState() {
    super.initState();
    _settingsStorage = widget.settingsStorage ?? SecureSettingsStorage();
    _modelListingService =
        widget.modelListingService ?? ProviderModelListingService();
    _chatService = widget.chatService ?? ProviderAiChatService();
    _contextRepository = widget.contextRepository ?? SecureContextRepository();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      const _AppDestination(
        title: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: HomeScreen(),
      ),
      const _AppDestination(
        title: 'Health',
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        screen: HealthScreen(),
      ),
      _AppDestination(
        title: 'Coach',
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        screen: CoachChatScreen(
          settingsStorage: _settingsStorage,
          chatService: _chatService,
          contextRepository: _contextRepository,
        ),
      ),
      _AppDestination(
        title: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        screen: SettingsScreen(
          settingsStorage: _settingsStorage,
          modelListingService: _modelListingService,
        ),
      ),
    ];
    final destination = destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(destination.title)),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (final destination in destinations) destination.screen,
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
          for (final destination in destinations)
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
