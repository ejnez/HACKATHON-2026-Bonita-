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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Unfurl",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          _buildItem(
            context,
            icon: Icons.list,
            title: "Tasks",
            route: '/',
          ),

          _buildItem(
            context,
            icon: Icons.timer,
            title: "Focus",
            route: '/focus',
          ),

          _buildItem(
            context,
            icon: Icons.local_florist,
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
            icon: Icons.login,
            title: "Login",
            route: '/login',
          ),
        ],
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
        color: selected
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      selected: selected,
      onTap: () {
        Navigator.pop(context); // close drawer

        if (!selected) {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}