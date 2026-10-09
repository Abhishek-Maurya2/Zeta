import 'package:flutter_localizations/flutter_localizations.dart'
    as flutter_localizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zeta/features/auth/presentation/auth_provider.dart';
import 'package:zeta/features/auth/presentation/login_page.dart';
import 'package:zeta/features/auth/presentation/signup_page.dart';
import 'package:zeta/components/zeta_logo.dart';

void main() {
  Widget buildTestableAuthPage({
    AuthMode initialMode = AuthMode.signIn,
    bool unavailable = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          flutter_localizations.GlobalMaterialLocalizations.delegate,
          flutter_localizations.GlobalWidgetsLocalizations.delegate,
          flutter_localizations.GlobalCupertinoLocalizations.delegate,
        ],
        home: LoginPage(
          initialMode: initialMode,
          unavailable: unavailable,
        ),
      ),
    );
  }

  testWidgets('LoginPage renders ZetaLogo, header, and dual-pane layout', (tester) async {
    await tester.pumpWidget(buildTestableAuthPage());
    await tester.pump();

    // Verify brand logo and title
    expect(find.byType(ZetaLogo), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('to continue to Zeta'), findsOneWidget);

    // Verify Sign In fields & links
    expect(find.text('Email or phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('LoginPage toggles between Sign In and Create Account modes', (tester) async {
    await tester.pumpWidget(buildTestableAuthPage());
    await tester.pump();

    // Initially in Sign In mode (no Full name field)
    expect(find.text('Full name'), findsNothing);

    // Tap "Create account" action button
    final createAccountButton = find.text('Create account');
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    // Now in Create Account mode
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Sign in instead'), findsOneWidget);
  });

  testWidgets('SignupPage renders in Create Account mode by default', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: SignupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Sign in instead'), findsOneWidget);
  });

  testWidgets('LoginPage shows unavailable banner when service is offline', (tester) async {
    await tester.pumpWidget(buildTestableAuthPage(unavailable: true));
    await tester.pumpAndSettle();

    expect(find.text('Sync service unreachable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
