import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyCookie = 'yt_cookie';
  static const _keyLoggedIn = 'yt_logged_in';
  static const _keyVisitorData = 'yt_visitor_data';

  static String? _cachedCookie;
  static String? _cachedVisitorData;
  static bool? _cachedLoggedIn;

  static Future<void> saveCookie(String cookie) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCookie, cookie);
    await prefs.setBool(_keyLoggedIn, hasValidLoginCookie(cookie));
    _cachedCookie = cookie;
    _cachedLoggedIn = hasValidLoginCookie(cookie);
  }

  static Future<void> saveVisitorData(String visitorData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVisitorData, visitorData);
    _cachedVisitorData = visitorData;
  }

  static Future<String?> getCookie() async {
    if (_cachedCookie != null) return _cachedCookie;
    final prefs = await SharedPreferences.getInstance();
    _cachedCookie = prefs.getString(_keyCookie);
    return _cachedCookie;
  }

  static Future<String?> getVisitorData() async {
    if (_cachedVisitorData != null) return _cachedVisitorData;
    final prefs = await SharedPreferences.getInstance();
    _cachedVisitorData = prefs.getString(_keyVisitorData);
    return _cachedVisitorData;
  }

  static Future<bool> isLoggedIn() async {
    if (_cachedLoggedIn != null) return _cachedLoggedIn!;
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString(_keyCookie);
    if (cookie == null || cookie.isEmpty) {
      _cachedLoggedIn = false;
      return false;
    }
    _cachedLoggedIn = hasValidLoginCookie(cookie);
    return _cachedLoggedIn!;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCookie);
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyVisitorData);
    _cachedCookie = null;
    _cachedLoggedIn = false;
    _cachedVisitorData = null;
  }

  static bool hasValidLoginCookie(String cookie) {
    final map = _parseCookieString(cookie);
    final loginInfo = map['LOGIN_INFO'];
    if (loginInfo == null || loginInfo.isEmpty) return false;
    const names = ['SAPISID', '__Secure-3PAPISID', '__Secure-1PAPISID'];
    return names.any((n) => map[n]?.isNotEmpty == true);
  }

  static Map<String, String> _parseCookieString(String cookie) {
    return Map.fromEntries(
      cookie
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) {
        final idx = e.indexOf('=');
        if (idx == -1) return null;
        return MapEntry(e.substring(0, idx).trim(), e.substring(idx + 1).trim());
      }).where((e) => e != null).cast<MapEntry<String, String>>(),
    );
  }

  static String cookieHeader(String cookie) => cookie;
}