import 'app_exit_stub.dart';
export 'app_exit_stub.dart';

class IOAppExitPlatformAdapter implements AppExitPlatformAdapter {
  @override
  void init(ExitCheckCallback isExitConfirmationNeeded) {}
}

AppExitPlatformAdapter getAppExitPlatformAdapter() =>
    IOAppExitPlatformAdapter();
