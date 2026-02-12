import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('terms')
          .get();
      if (doc.exists && doc.data() != null && doc.data()!['content'] != null) {
        String content = doc.data()!['content'];
        if (!content.contains('<html>')) {
          content =
              '''
            <!DOCTYPE html>
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body { font-family: sans-serif; line-height: 1.6; padding: 16px; color: #333; }
                @media (prefers-color-scheme: dark) {
                  body { color: #eee; background-color: #121212; }
                }
              </style>
            </head>
            <body>$content</body>
            </html>
          ''';
        }
        await _controller.loadHtmlString(content);
      } else {
        await _controller.loadHtmlString(
          '<h3>Terms & Conditions</h3><p>No content available.</p>',
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load terms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Stack(
        children: [
          if (_error != null)
            Center(child: Text(_error!))
          else
            WebViewWidget(controller: _controller),

          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
