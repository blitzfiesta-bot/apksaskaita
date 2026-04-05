import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const String kBaseUrl = 'https://saskaitaonline.lt';
const String kStartUrl = 'https://saskaitaonline.lt/client/dashboard.php';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _offline  = false;
  double _progress = 0;
  String _currentUrl = kStartUrl;
  bool _canGoBack = false;
  StreamSubscription? _connectSub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initWebView();
  }

  void _initConnectivity() {
    _connectSub = Connectivity().onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      if (online && _offline) {
        setState(() => _offline = false);
        _ctrl.reload();
      }
    });
  }

  void _initWebView() {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0F))
      ..setUserAgent(
          'SaskaitaOnlineLT/1.0 Flutter Android (saskaitaonline.lt mobile app)')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            _loading = true;
            _currentUrl = url;
          });
          _updateCanGoBack();
        },
        onPageFinished: (url) {
          setState(() => _loading = false);
          _updateCanGoBack();
          // Injektuoti mobiliojo optimizavimo JS
          _ctrl.runJavaScript('''
            document.documentElement.style.setProperty('--app-mode', 'mobile-app');
            // Paslepiame PWA install banner (jau esame programėlėje)
            var pwa = document.getElementById('pwa-install-card');
            if(pwa) pwa.style.display='none';
          ''');
        },
        onProgress: (p) => setState(() => _progress = p / 100),
        onWebResourceError: (err) {
          if (err.isForMainFrame == true) {
            setState(() { _offline = true; _loading = false; });
          }
        },
        onNavigationRequest: (req) {
          // Išorinės nuorodos - atidaryti sistemoje
          if (!req.url.startsWith(kBaseUrl) &&
              !req.url.startsWith('about:') &&
              !req.url.startsWith('data:')) {
            // Leisti URL launcher atidaryti
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(kStartUrl));
  }

  void _updateCanGoBack() async {
    final can = await _ctrl.canGoBack();
    if (mounted) setState(() => _canGoBack = can);
  }

  @override
  void dispose() {
    _connectSub?.cancel();
    super.dispose();
  }

  // Android Back button
  Future<bool> _onWillPop() async {
    if (await _ctrl.canGoBack()) {
      _ctrl.goBack();
      return false;
    }
    // Patvirtinimo dialogas išėjimui
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Uždaryti programėlę?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text('Ar tikrai norite išeiti?',
            style: TextStyle(color: Colors.white60, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ne', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F5FE0)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Taip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Stack(
          children: [
            // WebView
            if (!_offline)
              SafeArea(
                child: WebViewWidget(controller: _ctrl),
              ),

            // Offline ekranas
            if (_offline)
              _buildOfflineScreen(),

            // Progreso juosta
            if (_loading && !_offline)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0, right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2F5FE0)),
                ),
              ),
          ],
        ),
        // Apatinė navigacijos juosta (tik mobiliame)
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildOfflineScreen() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      color: Color(0xFF6B6B7A), size: 40),
                ),
                const SizedBox(height: 24),
                const Text('Nėra interneto ryšio',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text('Patikrinkite Wi-Fi arba mobilųjį ryšį ir bandykite dar kartą',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _offline = false);
                    _ctrl.reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5FE0),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('Bandyti dar kartą',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(Icons.dashboard_rounded, 'Apžvalga', '/client/dashboard.php'),
      _NavItem(Icons.receipt_long_rounded, 'Nauja SF', '/client/order.php'),
      _NavItem(Icons.people_rounded, 'Klientai', '/client/contacts.php'),
      _NavItem(Icons.account_balance_wallet_rounded, 'Išlaidos', '/client/expenses.php'),
      _NavItem(Icons.more_horiz_rounded, 'Daugiau', '/client/profile.php'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111117),
        border: Border(top: BorderSide(color: Color(0xFF1E1E2A), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final active = _currentUrl.contains(item.path);
            return Expanded(
              child: InkWell(
                onTap: () {
                  _ctrl.loadRequest(Uri.parse('$kBaseUrl${item.path}'));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon,
                        size: 22,
                        color: active
                            ? const Color(0xFF2F5FE0)
                            : Colors.white.withOpacity(0.4)),
                      const SizedBox(height: 3),
                      Text(item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? const Color(0xFF2F5FE0)
                              : Colors.white.withOpacity(0.4),
                        )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem(this.icon, this.label, this.path);
}
