import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/audio_player_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AudioPlayerController.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, _, _) {
          final song = controller.current;
          if (song == null) {
            return const Center(child: Text('Nothing playing'));
          }
          return _buildNowPlaying(context, controller, song);
        },
      ),
    );
  }

  Widget _buildNowPlaying(
      BuildContext context, AudioPlayerController controller, Song song) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: song.thumbnail != null
                ? Image.network(
                    song.thumbnail!,
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _artworkPlaceholder(theme),
                  )
                : _artworkPlaceholder(theme),
          ),
          const SizedBox(height: 32),
          Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            song.artist,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          _progress(context, controller),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 36,
                onPressed: controller.playPrevious,
                icon: const Icon(Icons.skip_previous),
              ),
              _playPause(controller),
              IconButton(
                iconSize: 36,
                onPressed: controller.playNext,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progress(BuildContext context, AudioPlayerController controller) {
    final theme = Theme.of(context);
    Duration position = controller.position;
    Duration total = controller.duration;
    return Column(
      children: [
        Slider(
          max: total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1,
          value: total.inMilliseconds > 0
              ? position.inMilliseconds
                  .clamp(0, total.inMilliseconds)
                  .toDouble()
              : 0,
          onChanged: (value) {
            controller.seek(Duration(milliseconds: value.toInt()));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position), style: theme.textTheme.bodySmall),
              Text(_fmt(total), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _playPause(AudioPlayerController controller) {
    if (controller.isLoading) {
      return const SizedBox(
        width: 72,
        height: 72,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return IconButton.filled(
      iconSize: 44,
      onPressed: controller.togglePlayPause,
      icon: Icon(
        controller.isPlaying ? Icons.pause_circle : Icons.play_circle,
      ),
    );
  }

  Widget _artworkPlaceholder(ThemeData theme) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.music_note,
        size: 120,
        color: theme.colorScheme.secondary,
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }
}
