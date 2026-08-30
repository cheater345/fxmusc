import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/search_screen.dart';
import 'widgets/mini_player.dart';

void main() {
  runApp(const FxmMusicApp());
}

class FxmMusicApp extends StatelessWidget {
  const FxmMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fxmusc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), SearchScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
          ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) =>
                setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.trending_up),
                label: 'Trending',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
