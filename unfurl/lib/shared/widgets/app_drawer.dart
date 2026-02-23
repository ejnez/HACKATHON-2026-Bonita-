import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unfurl/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBF9), Color(0xFFE8F0EB)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6FAF98), Color(0xFF8CB29E)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          'assets/icon/Unfurl_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Unfurl',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: StreamBuilder<User?>(
                      stream: AuthService.authStateChanges,
                      builder: (context, snapshot) {
                        final email = snapshot.data?.email;
                        return Text(
                          email ?? 'Signed out',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildItem(
              context,
              icon: Icons.list_alt_rounded,
              title: 'Tasks',
              route: '/',
            ),
            _buildItem(
              context,
              icon: Icons.timer_outlined,
              title: 'Focus',
              route: '/focus',
            ),
            _buildItem(
              context,
              icon: Icons.local_florist_outlined,
              title: 'Flowers',
              route: '/flowers',
            ),
            _buildItem(
              context,
              icon: Icons.auto_awesome,
              title: 'Unload My Brain',
              route: '/chatbot',
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final loggedIn = user != null;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Icon(loggedIn ? Icons.logout_rounded : Icons.login_rounded),
                    title: Text(loggedIn ? 'Logout' : 'Login'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: Colors.white.withValues(alpha: 0.6),
                    iconColor: const Color(0xFF4F635A),
                    textColor: const Color(0xFF4F635A),
                    onTap: () async {
                      Navigator.pop(context);

                      try {
                        if (loggedIn) {
                          await AuthService.signOut();
                        } else {
                          await AuthService.signInWithGoogle();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final selected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 1),
        leading: Icon(
          icon,
          color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF6A7C74),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF4F635A),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedTileColor: const Color(0xFFDCECE4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          Navigator.pop(context);

          if (!selected) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
