import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            colors: [Color(0xFFF7F8F5), Color(0xFFEAF1EC)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6FAF98), Color(0xFF8CB29E)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icon/unfurl_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Unfurl",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildItem(
              context,
              icon: Icons.list_alt_rounded,
              title: "Tasks",
              route: '/',
            ),

            _buildItem(
              context,
              icon: Icons.timer_outlined,
              title: "Focus",
              route: '/focus',
            ),

            _buildItem(
              context,
              icon: Icons.local_florist_outlined,
              title: "Flowers",
              route: '/flowers',
            ),

            _buildItem(
              context,
              icon: Icons.auto_awesome,
              title: "Unload My Brain",
              route: '/chatbot',
            ),

            const Divider(),


            /// ⭐ Reactive Auth Button
            StreamBuilder<User?>(
              stream: AuthService.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                final loggedIn = user != null;


                return ListTile(
                  leading: Icon(
                    loggedIn ? Icons.logout : Icons.login,
                  ),
                  title: Text(
                    loggedIn ? "Logout" : "Login",
                  ),
                  onTap: () async {
                    Navigator.pop(context);


                    if (loggedIn) {
                      await AuthService.signOut();
                    } else {
                      await AuthService.signInWithGoogle();
                    }
                  },
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
    final bool selected = currentRoute == route;

    return ListTile(
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
      selectedTileColor: const Color(0xFFE1EEE7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context); // close drawer

        if (!selected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}
