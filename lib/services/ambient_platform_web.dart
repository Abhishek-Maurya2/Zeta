import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'ambient_platform_stub.dart';
export 'ambient_platform_stub.dart';

class WebAmbientPlatformAdapter implements AmbientPlatformAdapter {
  FullscreenChangeCallback? _listener;

  WebAmbientPlatformAdapter() {
    web.document.addEventListener(
      'fullscreenchange',
      ((web.Event event) {
        final isFs = isFullscreen;
        _listener?.call(isFs);
      }).toJS,
    );
  }

  @override
  Future<void> enterFullscreen() async {
    try {
      web.document.documentElement?.requestFullscreen();
    } catch (_) {}
  }

  @override
  Future<void> exitFullscreen() async {
    try {
      if (web.document.fullscreenElement != null) {
        web.document.exitFullscreen();
      }
    } catch (_) {}
  }

  @override
  bool get isFullscreen => web.document.fullscreenElement != null;

  @override
  void setFullscreenListener(FullscreenChangeCallback? callback) {
    _listener = callback;
  }
}

AmbientPlatformAdapter getAmbientPlatformAdapter() =>
    WebAmbientPlatformAdapter();
