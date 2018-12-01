// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef void WebViewCreatedCallback(WebViewController controller);

enum JavaScriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

/// A web view widget for showing html content.
class WebView extends StatefulWidget {
  /// Creates a new web view.
  ///
  /// The web view can be controlled using a `WebViewController` that is passed to the
  /// `onWebViewCreated` callback once the web view is created.
  ///
  /// The `javaScriptMode` parameter must not be null.
  const WebView({
    Key key,
    this.onWebViewCreated,
    this.initialUrl,
    this.javaScriptMode = JavaScriptMode.disabled,
    this.gestureRecognizers,
  })  : assert(javaScriptMode != null),
        super(key: key);

  /// If not null invoked once the web view is created.
  final WebViewCreatedCallback onWebViewCreated;

  /// Which gestures should be consumed by the web view.
  ///
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// The initial URL to load.
  final String initialUrl;

  /// Whether JavaScript execution is enabled.
  final JavaScriptMode javaScriptMode;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();
  WebViewController _webController;

  _WebSettings _settings;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return GestureDetector(
        // We prevent text selection by intercepting the long press event.
        // This is a temporary stop gap due to issues with text selection on Android:
        // https://github.com/flutter/flutter/issues/24585 - the text selection
        // dialog is not responding to touch events.
        // https://github.com/flutter/flutter/issues/24584 - the text selection
        // handles are not showing.
        // TODO(amirh): remove this when the issues above are fixed.
        onLongPress: () {},
        child: AndroidView(
          viewType: 'com.hanihashemi.prowebview/webview',
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: widget.gestureRecognizers,
          // WebView content is not affected by the Android view's layout direction,
          // we explicitly set it here so that the widget doesn't require an ambient
          // directionality.
          layoutDirection: TextDirection.rtl,
          creationParams: _CreationParams.fromWidget(widget).toMap(),
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.hanihashemi.prowebview/webview',
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
        creationParams: _CreationParams.fromWidget(widget).toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the webview_flutter plugin');
  }

  @override
  void initState() {
    super.initState();
    _settings = _WebSettings.fromWidget(widget);
  }

  @override
  void didUpdateWidget(WebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final _WebSettings newSettings = _WebSettings.fromWidget(widget);
    final Map<String, dynamic> settingsUpdate =
    _settings.updatesMap(newSettings);
    _updateSettings(settingsUpdate);
    _settings = newSettings;
  }

  Future<void> _updateSettings(Map<String, dynamic> update) async {
    if (update == null) {
      return;
    }
    _webController = await _controller.future;
    _webController._updateSettings(update);
  }

  void _onPlatformViewCreated(int id) {
    final WebViewController controller = WebViewController._(id);
    _controller.complete(controller);
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated(controller);
    }
  }

  @override
  void dispose() {
    if (_webController != null) _webController.dispose();
    super.dispose();
  }
}

class _CreationParams {
  _CreationParams({this.initialUrl, this.settings});

  static _CreationParams fromWidget(WebView widget) {
    return _CreationParams(
      initialUrl: widget.initialUrl,
      settings: _WebSettings.fromWidget(widget),
    );
  }

  final String initialUrl;
  final _WebSettings settings;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'initialUrl': initialUrl,
      'settings': settings.toMap(),
    };
  }
}

class _WebSettings {
  _WebSettings({
    this.javaScriptMode,
  });

  static _WebSettings fromWidget(WebView widget) {
    return _WebSettings(javaScriptMode: widget.javaScriptMode);
  }

  final JavaScriptMode javaScriptMode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'jsMode': javaScriptMode.index,
    };
  }

  Map<String, dynamic> updatesMap(_WebSettings newSettings) {
    if (javaScriptMode == newSettings.javaScriptMode) {
      return null;
    }
    return <String, dynamic>{
      'jsMode': newSettings.javaScriptMode.index,
    };
  }
}

/// Controls a [WebView].
///
/// A [WebViewController] instance can be obtained by setting the [WebView.onWebViewCreated]
/// callback for a [WebView] widget.
class WebViewController {
  WebViewController._(int id) {
    _channel = MethodChannel('com.hanihashemi.prowebview/webview_$id');
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onUrlChanged':
          _onUrlChanged.add(call.arguments['url']);
          break;
        default:
          throw MissingPluginException(
            '${call.method} method not implemented on the Dart side.',
          );
      }
    });
  }

  MethodChannel _channel;

  final _onUrlChanged = StreamController<String>.broadcast();
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  Future<void> loadUrl(String url) async {
    assert(url != null);
    _validateUrlString(url);
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<void> reload() async {
    return _channel.invokeMethod('reload');
  }

  Future<void> goBack() async {
    return _channel.invokeMethod('goBack');
  }

  Future<void> goForward() async {
    return _channel.invokeMethod('goForward');
  }

  Future<void> _updateSettings(Map<String, dynamic> update) async {
    return _channel.invokeMethod('updateSettings', update);
  }

  void dispose() {
    _onUrlChanged.close();
  }
}

// Throws an ArgumentError if url is not a valid url string.
void _validateUrlString(String url) {
  try {
    final Uri uri = Uri.parse(url);
    if (uri.scheme.isEmpty) {
      throw ArgumentError('Missing scheme in URL string: "$url"');
    }
  } on FormatException catch (e) {
    throw ArgumentError(e);
  }
}