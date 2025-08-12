import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HPPCheckout extends StatefulWidget {
  const HPPCheckout({
    Key? key,
    required this.hppURL,
    required this.sessionId,
    required this.returnURL,
  }) : super(key: key);

  final String hppURL;
  final String sessionId;
  final String? returnURL;

  @override
  State<HPPCheckout> createState() => _HPPCheckoutState();
}

class _HPPCheckoutState extends State<HPPCheckout> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (message) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint("WebView progress: $progress%");
          },
          onPageStarted: (String url) {
            debugPrint("Page started: $url");
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint("Page finished: $url");
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebResourceError: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request to: ${request.url}');

            // If return URL is reached → close WebView & return result
            if ((widget.returnURL ?? "").isNotEmpty &&
                request.url.startsWith(widget.returnURL!)) {
              Navigator.pop(
                context,
                Uri.parse(request.url).queryParameters,
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate; // Allow normal navigation
          },
        ),
      )
      ..loadRequest(
        Uri.parse("${widget.hppURL}${widget.sessionId}"),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Match status bar color to app theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0.0, 0.0),
        child: Container(),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
