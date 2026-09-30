typedef ExitCheckCallback = bool Function();

abstract class AppExitPlatformAdapter {
  void init(ExitCheckCallback isExitConfirmationNeeded);
}

class StubAppExitPlatformAdapter implements AppExitPlatformAdapter {
  @override
  void init(ExitCheckCallback isExitConfirmationNeeded) {}
}

AppExitPlatformAdapter getAppExitPlatformAdapter() =>
    StubAppExitPlatformAdapter();
