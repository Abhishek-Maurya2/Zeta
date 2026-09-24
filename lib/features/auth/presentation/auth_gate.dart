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
    if (auth.status == AuthStatus.loading) {
      return const SizedBox.shrink();
    }
    if (auth.status == AuthStatus.signedIn) {
      return authenticatedBuilder(context);
    }
    return LoginPage(unavailable: auth.status == AuthStatus.unavailable);
  }
}
