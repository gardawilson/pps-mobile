import 'package:flutter/material.dart';

class AppDrawerColors {
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryDark = Color(0xFF0F2354);
  static const Color ink = Color(0xFF1E293B);
  static const Color slate = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFF1F5F9);
}

class _DrawerMenuData {
  final String route;
  final IconData icon;
  final String label;
  final Color color;

  const _DrawerMenuData({
    required this.route,
    required this.icon,
    required this.label,
    required this.color,
  });
}

const List<_DrawerMenuData> _menuItems = [
  _DrawerMenuData(
    route: '/home',
    icon: Icons.space_dashboard_rounded,
    label: 'Dashboard',
    color: AppDrawerColors.primary,
  ),
  _DrawerMenuData(
    route: '/stockopname',
    icon: Icons.checklist_rtl_rounded,
    label: 'Stock Opname',
    color: AppDrawerColors.primary,
  ),
  _DrawerMenuData(
    route: '/stockopname-v2',
    icon: Icons.inventory_2_outlined,
    label: 'Stock Opname V2',
    color: Color(0xFF5B21B6),
  ),
  _DrawerMenuData(
    route: '/mapping-v2',
    icon: Icons.map_rounded,
    label: 'Mapping V2',
    color: Color(0xFF0369A1),
  ),
  _DrawerMenuData(
    route: '/bj-jual',
    icon: Icons.sell_rounded,
    label: 'Penjualan BJ',
    color: Color(0xFF92400E),
  ),
];

/// Sidebar shared by the dashboard and every feature screen so the menu
/// stays reachable without needing to navigate back to the dashboard first.
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  void _openMenu(BuildContext context, String route) {
    Navigator.pop(context);
    if (route == currentRoute) return;
    if (route == '/home') {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        ModalRoute.withName('/home'),
      );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 288,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: AppDrawerColors.primary,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PPS Mobile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Plastic Production System',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppDrawerColors.slate,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: _menuItems
                    .map(
                      (item) => _DrawerItem(
                        icon: item.icon,
                        label: item.label,
                        color: item.color,
                        selected: item.route == currentRoute,
                        onTap: () => _openMenu(context, item.route),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Divider(height: 1, color: AppDrawerColors.border),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Keluar',
                color: const Color(0xFFB91C1C),
                onTap: () => _logout(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'PPS Mobile v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppDrawerColors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppDrawerColors.primary.withOpacity(0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? color : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? color : AppDrawerColors.slate,
                  size: 21,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppDrawerColors.ink : AppDrawerColors.slate.withOpacity(0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
