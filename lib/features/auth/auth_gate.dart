// lib/features/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';   // exposes authStateProvider (StreamProvider<User?>)
import '../shell/app_shell.dart';       // bottom-nav shell (Home/Profile/Settings)
import 'sign_in_view.dart';             // <-- your existing sign-in screen

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (user) => user == null
          ? const SignInView()          // not signed in -> your sign-in screen
          : const AppShell(),           // signed in -> app shell
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SignInView(), // fallback to sign-in on error
    );
  }
}
