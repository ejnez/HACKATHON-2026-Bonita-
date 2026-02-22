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
                  width: 330,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFCFE3)),
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Text(
                        'Bloom',
                        style: TextStyle(
                          fontSize: 30,
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
                        'Keep your tasks and bouquet synced across devices.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: AuthService.signInWithGoogle,
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Continue with Google'),
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
                width: 330,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFCFE3)),
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Text(
                      "Logged in as",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      user.email ?? "",
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

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