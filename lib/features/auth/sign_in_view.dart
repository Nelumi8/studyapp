import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

class SignInView extends ConsumerStatefulWidget {
  const SignInView({super.key});
  @override
  ConsumerState<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends ConsumerState<SignInView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _run(Future<void> Function() f) async {
    setState(() { _loading = true; _error = null; });
    try { await f(); } catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : () => _run(() async {
                await auth.signInWithEmail(_email.text.trim(), _password.text);
              }),
              child: _loading ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            TextButton(
              onPressed: _loading ? null : () => _run(() async {
                await auth.registerWithEmail(_email.text.trim(), _password.text);
              }),
              child: const Text('Create account'),
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: _loading ? null : () => _run(() async {
                await auth.signInWithGoogle();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
