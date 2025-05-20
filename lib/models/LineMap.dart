// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LineHome extends StatefulWidget {
  const LineHome({super.key});

  @override
  _LineHomeState createState() => _LineHomeState();
}

class _LineHomeState extends State<LineHome> {
  late WebViewController controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = LoadingAnimationWidget.horizontalRotatingDots(
          color: const Color.fromARGB(255, 54, 193, 163), size: 100);
    });
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color.fromARGB(0, 14, 69, 80))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {
            setState(() {
              isLoading = null;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('${getUrl()}mapline'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Home'),
      ),
      body: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Card(
                clipBehavior: Clip.hardEdge,
                elevation: 2,
                child: WebViewWidget(controller: controller),
              )),
          Center(
            child: isLoading,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.reload();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
