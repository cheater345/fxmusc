import 'dart:convert';
import 'package:http/http.dart' as http;

/// Minimal InnerTube service for authenticated stream extraction.
/// Mirrors ArchiveTune's approach: call youtubei/v1/player with Cookie + visitorData
/// and fallback through multiple clients (WEB_REMIX -> ANDROID_MUSIC -> WEB)
class InnertubeService {
  static const _key = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
  static const _baseUrl = 'https://www.youtube.com/youtubei/v1';

  static const List<Map<String, String>> _clients = [
    {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20240823.01.00',
      'userAgent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    },
    {
      'clientName': 'ANDROID_MUSIC',
      'clientVersion': '7.04.52',
      'userAgent': 'com.google.android.apps.youtube.music/7.04.52 (Linux; U; Android 13)',
    },
    {
      'clientName': 'WEB',
      'clientVersion': '2.20240823.01.00',
      'userAgent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    },
  ];

  /// Try to get audio stream URL with authenticated player request.
  /// Returns null if all clients fail.
  static Future<String?> getAudioStreamUrl(
    String videoId, {
    String? cookie,
    String? visitorData,
  }) async {
    for (final client in _clients) {
      try {
        final url = await _tryClient(videoId, client, cookie: cookie, visitorData: visitorData);
        if (url != null) return url;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<String?> _tryClient(
    String videoId,
    Map<String, String> client, {
    String? cookie,
    String? visitorData,
  }) async {
    final body = {
      'context': {
        'client': {
          'clientName': client['clientName'],
          'clientVersion': client['clientVersion'],
          'hl': 'en',
          'gl': 'US',
          if (visitorData != null && visitorData.isNotEmpty) 'visitorData': visitorData,
        },
      },
      'videoId': videoId,
      'contentCheckOk': true,
      'racyCheckOk': true,
      'playbackContext': {
        'contentPlaybackContext': {'html5Preference': 'HTML5_PREF_WANTS'}
      },
    };

    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': client['userAgent']!,
      'Origin': 'https://music.youtube.com',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/player?key=$_key'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final playability = (data['playabilityStatus'] as Map<String, dynamic>?)?['status'] as String?;
    if (playability != 'OK') return null;

    final streamingData = data['streamingData'] as Map<String, dynamic>?;
    if (streamingData == null) return null;

    final formats = (streamingData['adaptiveFormats'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final audio = formats.where((f) {
      final mime = f['mimeType'] as String? ?? '';
      return mime.startsWith('audio/');
    }).toList();

    if (audio.isEmpty) return null;

    audio.sort((a, b) {
      final ba = (a['averageBitrate'] as int?) ?? (a['bitrate'] as int?) ?? 0;
      final bb = (b['averageBitrate'] as int?) ?? (b['bitrate'] as int?) ?? 0;
      return bb.compareTo(ba);
    });

    final best = audio.first;
    final url = best['url'] as String?;
    if (url == null || url.isEmpty) return null;
    return url;
  }
}