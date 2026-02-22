import 'package:flutter/material.dart';

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
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6FAF98), Color(0xFF8CB29E)],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Unfurl",
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

            _buildItem(
              context,
              icon: Icons.favorite_border_rounded,
              title: "Login",
              route: '/login',
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
