import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/audio_player_controller.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = AudioPlayerController.instance;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, _, __) {
        final song = controller.current;
        if (song == null) {
          return const SizedBox.shrink();
        }
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _thumb(context, song),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: controller.togglePlayPause,
                      icon: Icon(
                        controller.isLoading
                            ? Icons.hourglass_top
                            : controller.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.playNext,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(BuildContext context, Song song) {
    final theme = Theme.of(context);
    if (song.thumbnail == null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.music_note,
            color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        song.thumbnail!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 44,
          height: 44,
          color: theme.colorScheme.surfaceContainerHighest,
          child:
              Icon(Icons.music_note, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
