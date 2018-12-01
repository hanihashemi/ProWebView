// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:pro_web_view/pro_web_view.dart';

void main() => runApp(MaterialApp(home: WebViewExample()));

class WebViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WebViewExample();
  }
}

class _WebViewExample extends State<WebViewExample> {
  static final initialUrl = 'https://hanihashemi.com/';
  WebViewController _webController;
  TextEditingController _addressBarController =
      TextEditingController(text: initialUrl);

  @override
  Widget build(BuildContext context) {
    final WebView webView = WebView(
      initialUrl: initialUrl,
      javaScriptMode: JavaScriptMode.unrestricted,
      onWebViewCreated: (WebViewController controller) {
        _webController = controller;
        _webController.onUrlChanged.listen((String url) {
          _addressBarController.text = url;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _addressBarController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          onSubmitted: _onSubmitAddress,
        ),
      ),
      body: webView,
      bottomNavigationBar: Container(
          height: 80.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.refresh),
                  iconSize: 24.0,
                  onPressed: _onReloadPressed),
              IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 24.0,
                  onPressed: _onBackPressed),
              IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  iconSize: 24.0,
                  onPressed: _onForwardPressed),
            ],
          )),
    );
  }

  void _onSubmitAddress(String text) {
    _webController.loadUrl(text);
  }

  void _onReloadPressed() {
    _webController.reload();
  }

  void _onBackPressed() {
    _webController.goBack();
  }

  void _onForwardPressed() {
    _webController.goForward();
  }
}
