import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';
import 'package:zeta/components/user_avatar.dart';
import 'package:zeta/providers/profile_provider.dart';

void main() {
  testWidgets('UserAvatar renders circle shape by default with glow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserAvatar(
                radius: 20,
                ringColor: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'UserAvatar renders gem shape when shape is UserAvatarShape.gem with glow (topappbar)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserAvatar(
                radius: 20,
                ringColor: Colors.green,
                shape: UserAvatarShape.gem,
                showGlow: true,
                showRing: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byType(ClipPath), findsOneWidget);
    final clipPath = tester.widget<ClipPath>(find.byType(ClipPath));
    expect(clipPath.clipper, isA<M3EShapeClipper>());
    expect(
      (clipPath.clipper as M3EShapeClipper).kind,
      equals(M3EShapeKind.gem),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'UserAvatar renders bun shape when shape is UserAvatarShape.bun with glow (profilemenu)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserAvatar(
                radius: 28,
                ringColor: Colors.amber,
                shape: UserAvatarShape.bun,
                showGlow: true,
                showRing: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    final clipPath = tester.widget<ClipPath>(find.byType(ClipPath));
    expect(
      (clipPath.clipper as M3EShapeClipper).kind,
      equals(M3EShapeKind.bun),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'UserAvatar renders cookie9Sided shape when shape is UserAvatarShape.cookie9Sided with glow (profilesection)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: UserAvatar(
                radius: 36,
                ringColor: Colors.purple,
                shape: UserAvatarShape.cookie9Sided,
                showGlow: true,
                showRing: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(UserAvatar), findsOneWidget);
    final clipPath = tester.widget<ClipPath>(find.byType(ClipPath));
    expect(
      (clipPath.clipper as M3EShapeClipper).kind,
      equals(M3EShapeKind.cookie9Sided),
    );
    expect(tester.takeException(), isNull);
  });
}
