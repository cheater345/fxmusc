import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final CookieManager _cookieManager = CookieManager.instance();
  bool _saving = false;
  String _status = 'Mag-login sa Google para ma-unlock ang lahat ng kanta';
  InAppWebViewController? _controller;

  Future<void> _checkLogin() async {
    setState(() => _saving = true);
    try {
      final cookiesMusic = await _cookieManager.getCookies(url: WebUri('https://music.youtube.com'));
      final cookiesYoutube = await _cookieManager.getCookies(url: WebUri('https://www.youtube.com'));
      final cookiesGoogle = await _cookieManager.getCookies(url: WebUri('https://accounts.google.com'));

      final allCookies = [...cookiesMusic, ...cookiesYoutube, ...cookiesGoogle];
      final cookieHeader = allCookies.map((c) => '${c.name}=${c.value}').join('; ');

      if (cookieHeader.isEmpty || !AuthService.hasValidLoginCookie(cookieHeader)) {
        if (mounted) {
          setState(() {
            _status = 'Hindi pa naka-login. Tapusin ang login sa itaas, tapos pindutin "I-check ulit".';
            _saving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hindi pa naka-detect ng login cookie. Mag-login muna.')),
          );
        }
        return;
      }

      await AuthService.saveCookie(cookieHeader);

      // Try to get visitorData from cookies or page
      // For now just save empty; Innertube will work with cookie alone for many tracks
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login success! Naka-save na.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _cookieManager.deleteAllCookies();
    await AuthService.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out. Cookies deleted.')));
      setState(() => _status = 'Logged out. Mag-login ulit kung kailangan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login sa YouTube Music'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Logout'),
          IconButton(
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_status, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _checkLogin,
                          icon: _saving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle),
                          label: const Text('I-check & I-save Login'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Isara'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tip: Mag-login gamit Google account mo. Pag nakita mo na yung music.youtube.com home, pindutin "I-check & I-save".',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('https://accounts.google.com/ServiceLogin?continue=https://music.youtube.com')),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                thirdPartyCookiesEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                clearCache: false,
                useShouldOverrideUrlLoading: false,
              ),
              onWebViewCreated: (c) => _controller = c,
              onLoadStop: (controller, url) async {
                // Auto-detect if user already logged in
                final cookies = await _cookieManager.getCookies(url: WebUri('https://music.youtube.com'));
                final header = cookies.map((c) => '${c.name}=${c.value}').join('; ');
                if (AuthService.hasValidLoginCookie(header)) {
                  if (mounted) setState(() => _status = 'Naka-detect na ng login cookie! Pindutin "I-check & I-save".');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}