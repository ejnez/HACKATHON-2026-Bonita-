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
            colors: [Color(0xFFFFF8FB), Color(0xFFFFEBF4)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF77B2), Color(0xFFFFA077)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Bouquet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
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
        color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF9D6D84),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF6C4D5E),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFFFE4F0),
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
