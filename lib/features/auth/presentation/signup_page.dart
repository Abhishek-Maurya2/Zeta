import 'package:flutter/material.dart';

import 'login_page.dart';

/// Signup page forwarding to the Material 3 Expressive unified authentication view in sign up mode.
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage(initialMode: AuthMode.signUp);
  }
}
