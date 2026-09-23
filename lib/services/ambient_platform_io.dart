import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/windows_title_bar.dart';
import 'ambient_platform_stub.dart';
export 'ambient_platform_stub.dart';

class IoAmbientPlatformAdapter implements AmbientPlatformAdapter {
  bool _isFullscreen = false;

  @override
  Future<void> enterFullscreen() async {
    _isFullscreen = true;
    if (Platform.isWindows) {
      await WindowsTitleBar.setFullscreen(true);
      await WindowsTitleBar.setWakeLock(true);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000),
          systemNavigationBarColor: Color(0x00000000),
          systemNavigationBarDividerColor: Color(0x00000000),
        ),
      );
    }
  }

  @override
  Future<void> exitFullscreen() async {
    _isFullscreen = false;
    if (Platform.isWindows) {
      await WindowsTitleBar.setFullscreen(false);
      await WindowsTitleBar.setWakeLock(false);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  void setFullscreenListener(FullscreenChangeCallback? callback) {}
}

AmbientPlatformAdapter getAmbientPlatformAdapter() =>
    IoAmbientPlatformAdapter();
