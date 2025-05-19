import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CCTVScreen extends StatefulWidget {
  final String universityUrl;

  CCTVScreen({required this.universityUrl});

  @override
  _CCTVScreenState createState() => _CCTVScreenState();
}

class _CCTVScreenState extends State<CCTVScreen> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('실시간 교통상황'),
        backgroundColor: Color(0xFF948BFF),
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.universityUrl),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: '''
                    document.body.style.zoom = "3.0";
                  ''',
                );
              },
              onProgressChanged: (controller, progress) {
                print("Loading progress: $progress%");
              },
            ),
          ),
        ],
      ),
    );
  }
}