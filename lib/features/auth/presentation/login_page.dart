import 'package:zeta/core/core.dart';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:provider/provider.dart';

import '../../../components/zeta_logo.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/haptics.dart';
import 'auth_provider.dart';

enum AuthMode { signIn, signUp }

/// Material 3 Expressive authentication page with Google-inspired dual-column card layout.
class LoginPage extends StatefulWidget {
  final bool unavailable;
  final AuthMode initialMode;

  const LoginPage({
    super.key,
    this.unavailable = false,
    this.initialMode = AuthMode.signIn,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late AuthMode _mode;
  bool _obscurePassword = true;
  Uint8List? _avatar;
  String _avatarExtension = 'jpg';

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    ZetaHaptics.light();
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return;
    final ext = file.name.split('.').last.toLowerCase();
    if (!mounted) return;
    setState(() {
      _avatar = bytes;
      _avatarExtension = const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext)
          ? (ext == 'jpeg' ? 'jpg' : ext)
          : 'jpg';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ZetaHaptics.medium();
      return;
    }
    ZetaHaptics.light();
    final auth = context.read<AuthProvider>();

    if (_mode == AuthMode.signIn) {
      await auth.signIn(email: _email.text.trim(), password: _password.text);
    } else {
      await auth.signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        avatarBytes: _avatar,
        avatarExtension: _avatarExtension,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _email.text.trim());
    final forgotFormKey = GlobalKey<FormState>();
    bool isSending = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = context.colorScheme;
            final textTheme = context.textTheme;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Form(
                  key: forgotFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          M3EShapeContainer(
                            kind: M3EShapeKind.cookie4Sided,
                            width: 44,
                            height: 44,
                            color: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset password',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "We'll send a recovery link to your inbox",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Account email',
                          prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            color: colorScheme.primary,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHigh
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
                            ? 'Enter a valid email address'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          M3EButton(
                            style: M3EButtonStyle.tonal,
                            size: M3EButtonSize.md,
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(bottomSheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          if (isSending)
                            const SizedBox.square(
                              dimension: 36,
                              child: Center(
                                child: M3ELoadingIndicator(
                                  variant:
                                      M3ELoadingIndicatorVariant.defaultStyle,
                                ),
                              ),
                            )
                          else
                            M3EButton.icon(
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.md,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Send link'),
                              onPressed: () async {
                                if (!forgotFormKey.currentState!.validate()) {
                                  return;
                                }
                                setSheetState(() => isSending = true);
                                ZetaHaptics.light();
                                final success = await context
                                    .read<AuthProvider>()
                                    .resetPassword(emailController.text.trim());
                                if (!context.mounted) return;
                                Navigator.of(bottomSheetContext).pop();
                                if (success) {
                                  AppSnackbar.show(
                                    context,
                                    message: 'Password reset link sent! Check your inbox.',
                                  );
                                } else {
                                  AppSnackbar.show(
                                    context,
                                    message: 'Could not send reset link. Please check your connection.',
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeftPane(BuildContext context, bool isWide) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSignIn = _mode == AuthMode.signIn;

    return Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Navigator.of(context).canPop()) ...[
          Align(
            alignment: isWide ? Alignment.centerLeft : Alignment.centerLeft,
            child: M3EIconButton(
              variant: M3EIconButtonVariant.standard,
              size: M3EIconButtonSize.sm,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Brand Logo inside Expressive Shape Container
        M3EShapeContainer(
          kind: M3EShapeKind.pill,
          width: 75,
          height: 75,
          color: colorScheme.tertiaryContainer,
          child: const Center(child: ZetaLogo(size: 50)),
        ),
        const SizedBox(height: 22),

        // Main Title
        Text(
          isSignIn ? 'Sign in' : 'Create account',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle / explanatory text
        Text(
          isSignIn ? 'to continue to Zeta' : 'to continue to Zeta',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRightPane(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final isSignIn = _mode == AuthMode.signIn;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar Picker (Sign Up mode)
          if (!isSignIn) ...[
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  InkWell(
                    onTap: _pickPhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: M3EShapeContainer(
                      kind: M3EShapeKind.cookie4Sided,
                      width: 150,
                      height: 150,
                      color: colorScheme.surfaceContainerHigh,
                      child: _avatar == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 30,
                                  color: colorScheme.secondary,
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                _avatar!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  if (_avatar != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: M3EIconButton(
                        variant: M3EIconButtonVariant.filled,
                        size: M3EIconButtonSize.sm,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          ZetaHaptics.selection();
                          setState(() => _avatar = null);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Full name',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) =>
                  !isSignIn && (value == null || value.trim().isEmpty)
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 14),
          ],

          if (isSignIn && MediaQuery.of(context).size.width > 600)
            const SizedBox(height: 80),
          // Email Field
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email or phone',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),

            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Enter a valid email address'
                : null,
          ),
          const SizedBox(height: 14),

          // Password Field
          TextFormField(
            controller: _password,
            obscureText: _obscurePassword,
            autofillHints: [
              isSignIn ? AutofillHints.password : AutofillHints.newPassword,
            ],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: isSignIn ? 'Password' : 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  size: M3EIconButtonSize.sm,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    ZetaHaptics.selection();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter your password';
              }
              if (!isSignIn && value.length < 8) {
                return 'Use at least 8 characters';
              }
              return null;
            },
          ),

          // Forgot password link
          if (isSignIn)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: M3EButton(
                  style: M3EButtonStyle.text,
                  size: M3EButtonSize.sm,
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('Forgot password?'),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Unavailable Status Alert
          if (widget.unavailable || auth.status == AuthStatus.unavailable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync service unreachable',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Check connection and try again.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  M3EButton.icon(
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    onPressed: () {
                      ZetaHaptics.light();
                      auth.retry();
                    },
                  ),
                ],
              ),
            ),
          ],

          // Error Alert Banner
          if (auth.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      auth.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.sm,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 16,
                    ),
                    onPressed: () => auth.clearError(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Bottom Action Row (Google Layout: Switch on left, Primary on right)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              M3EButton(
                style: M3EButtonStyle.text,
                size: M3EButtonSize.md,
                onPressed: () {
                  ZetaHaptics.selection();
                  setState(() {
                    _mode = isSignIn ? AuthMode.signUp : AuthMode.signIn;
                    auth.clearError();
                  });
                },
                child: Text(isSignIn ? 'Create account' : 'Sign in instead'),
              ),
              if (auth.isBusy)
                const SizedBox.square(
                  dimension: 36,
                  child: Center(
                    child: M3ELoadingIndicator(
                      variant: M3ELoadingIndicatorVariant.defaultStyle,
                    ),
                  ),
                )
              else
                M3EButton.icon(
                  size: M3EButtonSize.md,
                  style: M3EButtonStyle.filled,
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(isSignIn ? 'Next' : 'Create account'),
                ),
            ],
          ),
          if (isSignIn && MediaQuery.of(context).size.width > 600)
            const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Card Container (Split 2-column or stacked)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 25,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 720;

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 8,
                                      child: _buildLeftPane(context, true),
                                    ),
                                    const SizedBox(width: 48),
                                    Expanded(
                                      flex: 6,
                                      child: _buildRightPane(context),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLeftPane(context, false),
                                  const SizedBox(height: 28),
                                  _buildRightPane(context),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Outer Bottom Footer (Google style)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          spacing: 30,
                          children: [
                            Text(
                              'English (India)',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                  ),
                                  child: const Text('Help'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                  ),
                                  child: const Text('Privacy'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                  ),
                                  child: const Text('Terms'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
