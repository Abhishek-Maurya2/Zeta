import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'login_page.dart';

/// Routes signed-out users to auth and mounts the feature tree only for a user.
class AuthGate extends StatelessWidget {
  final WidgetBuilder authenticatedBuilder;
  final bool bypassAuth;

  const AuthGate({
    super.key,
    required this.authenticatedBuilder,
    this.bypassAuth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bypassAuth) return authenticatedBuilder(context);
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.loading && auth.isRestoringSession) {
      return const _AuthStartupLoadingView();
    }
    if (auth.status == AuthStatus.signedIn) {
      return authenticatedBuilder(context);
    }
    return LoginPage(unavailable: auth.status == AuthStatus.unavailable);
  }
}

class _AuthStartupLoadingView extends StatelessWidget {
  const _AuthStartupLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/logo/logo.png',
                width: 80,
                height: 80,
                cacheWidth: 160,
                cacheHeight: 160,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text('Preparing your account…', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
