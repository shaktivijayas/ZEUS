import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/app_spacing.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isSignUp ? 'Create your account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              if (_isSignUp)
                TextField(
                  key: const Key('auth_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
              TextField(
                key: const Key('auth_email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                key: const Key('auth_password_field'),
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ElevatedButton(
                key: const Key('auth_submit_button'),
                onPressed: _submitting ? null : _submit,
                child: Text(_isSignUp ? 'Sign up' : 'Log in'),
              ),
              TextButton(
                key: const Key('auth_toggle_mode_button'),
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(_isSignUp ? 'Already have an account? Log in' : "Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
