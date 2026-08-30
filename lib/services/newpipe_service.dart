import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';

import '../models/song.dart';

class NewPipeService {
  /// Searches YouTube Music for songs matching [query].
  static Future<List<Song>> searchMusic(String query) async {
    if (query.trim().isEmpty) {
      return const [];
    }
    try {
      final page = await SearchExtractor.searchYoutubeMusic(
        query.trim(),
        [SearchFilter.musicSongs.value],
      );
      return page.result.videos.map(_mapItem).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Searches YouTube (all content) as a fallback.
  static Future<List<Song>> searchAll(String query) async {
    final page = await SearchExtractor.searchYoutube(
      query.trim(),
      [SearchFilter.videos.value],
    );
    return page.result.videos.map(_mapItem).toList();
  }

  /// Returns the current YouTube trending videos as song items.
  static Future<List<Song>> trending() async {
    final page = await TrendingExtractor.getTrendingVideos();
    return page.items.map(_mapItem).toList();
  }

  /// Returns autocomplete suggestions for [query].
  static Future<List<String>> searchSuggestions(String query) async {
    if (query.trim().length < 3) {
      return const [];
    }
    try {
      return await SearchExtractor.getSearchSuggestions(query.trim());
    } catch (e) {
      rethrow;
    }
  }

  /// Resolves a playable audio stream URL for [song] by extracting the full
  /// video info and picking the best audio-only stream.
  static Future<String?> getPlayableUrl(String watchUrl) async {
    try {
      final video = await VideoExtractor.getStream(watchUrl);
      final audioStreams = video.audioOnlyStreams;
      if (audioStreams.isEmpty) {
        return null;
      }
      audioStreams.sort((a, b) => b.averageBitrate.compareTo(a.averageBitrate));
      return audioStreams.first.url;
    } catch (e) {
      return null;
    }
  }

  static Song _mapItem(StreamInfoItem item) {
    return Song(
      id: item.id ?? '',
      title: item.name ?? 'Unknown',
      artist: item.uploaderName ?? 'Unknown',
      url: item.url,
      thumbnail: item.thumbnails.isNotEmpty ? item.thumbnails.first : null,
      duration: item.duration,
      viewCount: item.viewCount,
    );
  }
}
