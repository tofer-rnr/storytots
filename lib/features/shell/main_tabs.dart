// lib/features/shell/main_tabs.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storytots/core/constants.dart';

import 'package:storytots/features/home/screens/home_screen.dart';
import 'package:storytots/features/library/screens/library_screen.dart';
import 'package:storytots/features/settings/screens/settings_screen.dart';
import 'package:storytots/features/games/games_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});
  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  static const _lastTabKey = 'last_selected_tab_index';
  int _index = 0;

  final _libraryKey = GlobalKey<LibraryScreenState>();

  late final List<Widget> _pages = [
    const HomeScreen(),
    const GamesScreen(),
    LibraryScreen(key: _libraryKey),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _restoreLastTab();
  }

  Future<void> _restoreLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    final i = prefs.getInt(_lastTabKey) ?? 0;
    if (!mounted) return;
    setState(() => _index = i.clamp(0, _pages.length - 1));
  }

  Future<void> _onTabTapped(int i) async {
    setState(() => _index = i);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastTabKey, i);

    // If switching to Library tab, refresh its content (including Favorites)
    if (i == 2) {
      _libraryKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyleSelected = const TextStyle(
      fontFamily: 'RustyHooks',
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );
    final labelStyleUnselected = const TextStyle(
      fontFamily: 'RustyHooks',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: _onTabTapped,
          backgroundColor: const Color(brandPurple),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          selectedLabelStyle: labelStyleSelected,
          unselectedLabelStyle: labelStyleUnselected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset_rounded),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_library_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
