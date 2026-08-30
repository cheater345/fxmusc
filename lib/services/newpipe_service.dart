import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

import '../models/song.dart';
import 'auth_service.dart';
import 'innertube_service.dart';

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
  /// Original design pa rin, pero pag `no audio stream available` at naka-login,
  /// mag-fallback sa authenticated InnerTube (gaya ng ArchiveTune backend).
  static Future<String?> getPlayableUrl(String watchUrl) async {
    // 1) Try NewPipe (unauthenticated) - original path
    try {
      String extractUrl = watchUrl;
      if (watchUrl.contains('music.youtube.com')) {
        extractUrl = watchUrl.replaceFirst('music.youtube.com', 'www.youtube.com');
      }
      final video = await VideoExtractor.getStream(extractUrl);
      final audioStreams = video.audioOnlyStreams;
      if (audioStreams.isNotEmpty) {
        audioStreams.sort((a, b) => b.averageBitrate.compareTo(a.averageBitrate));
        final url = audioStreams.first.url;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {
      // fallthrough to authenticated fallback
    }

    // 2) Fallback: authenticated InnerTube (requires login)
    try {
      final cookie = await AuthService.getCookie();
      final visitorData = await AuthService.getVisitorData();
      final loggedIn = await AuthService.isLoggedIn();
      if (loggedIn && cookie != null) {
        final videoId = _extractVideoId(watchUrl);
        if (videoId.isNotEmpty) {
          final authUrl = await InnertubeService.getAudioStreamUrl(
            videoId,
            cookie: cookie,
            visitorData: visitorData,
          );
          if (authUrl != null && authUrl.isNotEmpty) return authUrl;
        }
      }
    } catch (_) {}

    // 3) Fallback: youtube_explode_dart (handles cipher, throttling, n-sig)
    try {
      final videoId = _extractVideoId(watchUrl);
      if (videoId.isEmpty) return null;
      final yt = yt_explode.YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final audioOnly = manifest.audioOnly;
        if (audioOnly.isNotEmpty) {
          audioOnly.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
          return audioOnly.first.url.toString();
        }
        // fallback to muxed if no audioOnly
        final muxed = manifest.muxed;
        if (muxed.isNotEmpty) {
          muxed.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
          return muxed.first.url.toString();
        }
      } finally {
        yt.close();
      }
    } catch (_) {}

    return null;
  }

  static String _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v']!;
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'shorts') return uri.pathSegments[1];
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') return uri.pathSegments[1];
    return '';
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
