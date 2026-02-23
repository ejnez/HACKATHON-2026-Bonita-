import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';
import 'package:unfurl/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _signingIn = false;

  Future<void> _handleGoogleSignIn() async {
    if (_signingIn) return;
    setState(() => _signingIn = true);
    try {
      final credential = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (credential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in cancelled.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
      ),
      drawer: const AppDrawer(currentRoute: '/login'),

      body: Container(
        decoration: const BoxDecoration(
          gradient: blossomBackground,
        ),

        child: Center(
          child: StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, snapshot) {

              final user = snapshot.data;

              /// -------------------------
              /// NOT LOGGED IN
              /// -------------------------
              if (user == null) {
                return Container(
                  width: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD4E5DC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(31, 68, 53, 0.10),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE6F1EB),
                          border: Border.all(color: const Color(0xFFCDE2D8)),
                        ),
                        child: Image.asset('assets/icon/Unfurl_icon.png'),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Unfurl',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Sign in to grow your streak',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Keep tasks, streaks, and bouquets synced across devices.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signingIn ? null : _handleGoogleSignIn,
                          icon: _signingIn
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(_signingIn ? 'Signing in...' : 'Continue with Google'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              /// -------------------------
              /// LOGGED IN STATE
              /// -------------------------
              return Container(
                width: 350,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4E5DC)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(31, 68, 53, 0.10),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 48, color: sageGreen),
                    const SizedBox(height: 8),

                    Text(
                      "Logged in as",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      user.email ?? "",
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: AuthService.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text("Sign Out"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
