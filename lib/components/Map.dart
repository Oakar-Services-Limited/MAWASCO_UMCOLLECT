import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'Utils.dart'; // Ensure this utils.dart file has the getUrl() function.

class MyMap extends StatefulWidget {
  final double lat;
  final double lon;

  const MyMap({super.key, required this.lat, required this.lon});

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  late WebViewController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading = true; // Changed to bool for simplicity

  @override
  void initState() {
    super.initState();
    // Initialize the loading state
    isLoading = true;

    // Initialize the WebViewController
    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();
    controller = WebViewController.fromPlatformCreationParams(params);

    setupWebViewController();
  }

  void setupWebViewController() {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Optionally handle progress updates
          },
          onPageStarted: (String url) {
            // Optionally handle page start
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
            controller
                .runJavaScript('adjustMarker(${widget.lon},${widget.lat})');
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Optionally handle navigation requests
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('${getUrl()}homepage'));
  }

  @override
  void didUpdateWidget(covariant MyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lon != widget.lon) {
      controller.runJavaScript('adjustMarker(${widget.lon},${widget.lat})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F1), // Cream color
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: Colors.grey.withValues(alpha:0.1), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(82, 158, 158, 158),
                    offset: Offset(2.0, 2.0),
                    blurRadius: 5.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: WebViewWidget(controller: controller)),
          if (isLoading)
            Center(
              child: LoadingAnimationWidget.horizontalRotatingDots(
                  color: Colors.yellow, size: 100),
            ),
        ],
      ),
    );
  }
}
