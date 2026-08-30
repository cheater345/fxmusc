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
          'timeZone': 'Etc/UTC',
          'userAgent': client['userAgent']!,
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
      'Referer': 'https://music.youtube.com/',
      'X-Youtube-Utc-Offset': '0',
      'X-Youtube-Time-Zone': 'Etc/UTC',
      if (visitorData != null && visitorData.isNotEmpty) 'X-Goog-Visitor-Id': visitorData,
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
    // ArchiveTune allows OK only; but also handle LOGIN_REQUIRED with cookie
    if (playability != 'OK') {
      // If login required but we have cookie, still try to parse streamingData
      if (playability == 'LOGIN_REQUIRED' && (cookie == null || cookie.isEmpty)) return null;
      if (playability != 'OK' && playability != 'LOGIN_REQUIRED') return null;
    }

    final streamingData = data['streamingData'] as Map<String, dynamic>?;
    if (streamingData == null) return null;

    // Check both formats + adaptiveFormats (some clients put audio in formats)
    final allFormats = [
      ...(streamingData['formats'] as List<dynamic>? ?? []),
      ...(streamingData['adaptiveFormats'] as List<dynamic>? ?? []),
    ].cast<Map<String, dynamic>>();

    final audio = allFormats.where((f) {
      final mime = f['mimeType'] as String? ?? '';
      return mime.startsWith('audio/');
    }).toList();

    if (audio.isEmpty) return null;

    audio.sort((a, b) {
      final ba = (a['averageBitrate'] as int?) ?? (a['bitrate'] as int?) ?? 0;
      final bb = (b['averageBitrate'] as int?) ?? (b['bitrate'] as int?) ?? 0;
      return bb.compareTo(ba);
    });

    for (final best in audio) {
      // Direct url
      var url = best['url'] as String?;
      if (url != null && url.isNotEmpty) return url;

      // Handle cipher (ArchiveTune: signatureCipher / cipher)
      final cipher = (best['signatureCipher'] as String?) ?? (best['cipher'] as String?);
      if (cipher != null && cipher.isNotEmpty) {
        // cipher is url-encoded query string: url=...&s=...&sp=...
        // Try to extract url part; if s is present we need decipher but try url anyway
        // Many ANDROID clients return deciphered url, so this fallback rarely needed
        final params = Uri.splitQueryString(cipher);
        url = params['url'];
        if (url != null && url.isNotEmpty) {
          // If s (signature) present, append it (basic, not deciphered - may still fail)
          // ArchiveTune uses NewPipeUtils.getStreamUrl for proper decipher
          final s = params['s'];
          final sp = params['sp'] ?? 'sig';
          if (s != null && s.isNotEmpty) {
            final decodedUrl = Uri.decodeComponent(url);
            // Without proper decipher, s is useless; try without
            return decodedUrl;
          }
          return Uri.decodeComponent(url);
        }
      }
    }
    return null;
  }
}