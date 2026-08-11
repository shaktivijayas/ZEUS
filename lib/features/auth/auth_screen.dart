import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/dark_mockup_palette.dart';

// This screen intentionally uses DarkMockupPalette's fixed dark/neon
// palette rather than AppTheme's forest-green ColorScheme — it's a one-off
// match for a specific login mockup, not a change to the app-wide design
// system. See DarkMockupPalette's doc comment.
const _bg = DarkMockupPalette.background;
const _fieldFill = DarkMockupPalette.card;
const _brandGreen = DarkMockupPalette.accent;
const _mutedText = DarkMockupPalette.mutedText;
const _socialFill = DarkMockupPalette.card;
const _facebookBlue = DarkMockupPalette.facebookBlue;

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = true;
  bool _obscurePassword = true;
  bool _keepLoggedIn = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Redraws so the Log In / Sign Up button can react to field content
    // (filled vs. empty) the way the mockup's two reference states do.
    _emailController.addListener(_onFieldsChanged);
    _passwordController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty && _passwordController.text.isNotEmpty && !_submitting;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.setKeepLoggedIn(_keepLoggedIn);
      if (_isSignUp) {
        await repo.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await repo.signIn(email: _emailController.text.trim(), password: _passwordController.text);
      }
      // Sign-in/sign-up changed FirebaseAuth's current user, which the
      // router's `redirect` gate depends on. redirect only re-runs on
      // navigation, an attached refreshListenable, or an explicit
      // refresh() call (go_router 17.3.0), so trigger one explicitly.
      // `maybeOf` (rather than `of`) makes this a no-op in widget tests
      // that mount AuthScreen directly under a plain MaterialApp with no
      // GoRouter ancestor.
      if (mounted) GoRouter.maybeOf(context)?.refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _fieldFill,
        title: const Text('Reset password', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: _mutedText)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send reset link', style: TextStyle(color: _brandGreen)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reset link: $e')));
    }
  }

  void _socialComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$provider sign-in coming soon')));
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _mutedText),
        filled: true,
        fillColor: _fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _brandGreen, width: 1.5)),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _socialButton({required Widget icon, required Color background, required VoidCallback onPressed}) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(width: 52, height: 52, child: Center(child: icon)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ZEUS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _brandGreen,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isSignUp ? 'Sign Up' : 'Log In',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _isSignUp
                    ? 'To sign up, please enter your name, email address, and choose a password.'
                    : 'To log in, please enter your phone number or\nemail address and confirm your password.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _mutedText),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_isSignUp) ...[
                _fieldLabel('Name'),
                TextField(
                  key: const Key('auth_name_field'),
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Name'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _fieldLabel('Email or Phone Number'),
              TextField(
                key: const Key('auth_email_field'),
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('Email or Phone Number'),
              ),
              const SizedBox(height: AppSpacing.md),
              _fieldLabel('Password'),
              TextField(
                key: const Key('auth_password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _mutedText),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      key: const Key('auth_keep_logged_in_checkbox'),
                      value: _keepLoggedIn,
                      onChanged: (v) => setState(() => _keepLoggedIn = v ?? false),
                      activeColor: _brandGreen,
                      checkColor: Colors.black,
                      side: const BorderSide(color: _mutedText),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Keep me logged in', style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  TextButton(
                    key: const Key('auth_forgot_password_button'),
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(foregroundColor: _brandGreen, minimumSize: Size.zero, padding: EdgeInsets.zero),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                ),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('auth_submit_button'),
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF3A3A3A),
                    disabledForegroundColor: _mutedText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_isSignUp ? 'Sign Up' : 'Log In', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('or', textAlign: TextAlign.center, style: TextStyle(color: _mutedText)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(
                    icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 20),
                    background: _socialFill,
                    onPressed: () => _socialComingSoon('Google'),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _socialButton(
                    icon: const FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
                    background: _socialFill,
                    onPressed: () => _socialComingSoon('Apple'),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _socialButton(
                    icon: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.white, size: 20),
                    background: _facebookBlue,
                    onPressed: () => _socialComingSoon('Facebook'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  key: const Key('auth_toggle_mode_button'),
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: _mutedText, fontSize: 14),
                      children: [
                        TextSpan(text: _isSignUp ? 'Already have an account? ' : "Don't you have an account? "),
                        TextSpan(
                          text: _isSignUp ? 'Log in' : 'Sign Up',
                          style: const TextStyle(color: _brandGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
