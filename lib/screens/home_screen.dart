import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/audio_player_controller.dart';
import '../services/auth_service.dart';
import '../services/newpipe_service.dart';
import '../widgets/song_tile.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final v = await AuthService.isLoggedIn();
    if (mounted) setState(() => _loggedIn = v);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final songs = await NewPipeService.trending();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load trending. Check your connection.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending'),
        actions: [
          IconButton(
            tooltip: _loggedIn ? 'Logged in - pindutin para mag-logout/login ulit' : 'Login sa YouTube Music',
            icon: Icon(_loggedIn ? Icons.verified_user : Icons.login),
            color: _loggedIn ? Colors.greenAccent : null,
            onPressed: () async {
              final res = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (res == true || res == false) _checkLogin();
              if (!mounted) return;
              if (_loggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged in! Subukan ulit mag-play — authenticated stream na.')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_songs.isEmpty) {
      return const Center(child: Text('No songs found'));
    }
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return SongTile(
          song: song,
          onTap: () {
            AudioPlayerController.instance.playQueue(_songs, index);
          },
        );
      },
    );
  }
}
