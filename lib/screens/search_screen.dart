import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/audio_player_controller.dart';
import '../services/newpipe_service.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _suggestions = [];
  List<Song> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions.clear());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions =
            await NewPipeService.searchSuggestions(query.trim());
        if (mounted) setState(() => _suggestions
          ..clear()
          ..addAll(suggestions));
      } catch (_) {}
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _suggestions.clear();
    });
    try {
      final results = await NewPipeService.searchMusic(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _search,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _search(_controller.text),
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_suggestions.isNotEmpty) {
      return ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(s),
            onTap: () {
              _controller.text = s;
              _search(s);
            },
          );
        },
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text('Search for any song.'),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        return SongTile(
          song: song,
          onTap: () {
            AudioPlayerController.instance.playQueue(_results, index);
          },
        );
      },
    );
  }
}
