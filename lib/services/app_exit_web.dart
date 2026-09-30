import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'app_exit_stub.dart';
export 'app_exit_stub.dart';

class WebAppExitPlatformAdapter implements AppExitPlatformAdapter {
  ExitCheckCallback? _isExitConfirmationNeeded;

  @override
  void init(ExitCheckCallback isExitConfirmationNeeded) {
    _isExitConfirmationNeeded = isExitConfirmationNeeded;

    web.window.addEventListener(
      'beforeunload',
      ((web.BeforeUnloadEvent event) {
        if (_isExitConfirmationNeeded?.call() == true) {
          event.preventDefault();
          event.returnValue = '';
        }
      }).toJS,
    );
  }
}

AppExitPlatformAdapter getAppExitPlatformAdapter() =>
    WebAppExitPlatformAdapter();
