typedef FullscreenChangeCallback = void Function(bool isFullscreen);

abstract class AmbientPlatformAdapter {
  Future<void> enterFullscreen();
  Future<void> exitFullscreen();
  bool get isFullscreen;
  void setFullscreenListener(FullscreenChangeCallback? callback);
}

class StubAmbientPlatformAdapter implements AmbientPlatformAdapter {
  bool _isFullscreen = false;
  FullscreenChangeCallback? _listener;

  @override
  Future<void> enterFullscreen() async {
    _isFullscreen = true;
    _listener?.call(true);
  }

  @override
  Future<void> exitFullscreen() async {
    _isFullscreen = false;
    _listener?.call(false);
  }

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  void setFullscreenListener(FullscreenChangeCallback? callback) {
    _listener = callback;
  }
}

AmbientPlatformAdapter getAmbientPlatformAdapter() =>
    StubAmbientPlatformAdapter();
