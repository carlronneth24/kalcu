import 'package:flutter/material.dart';

/// Side drawer menu opened from the calculator's top-left menu icon.
/// Matches the Figma design: dark panel, right-aligned "Currency" and
/// "Length" items with icons, separated by thin dividers.
class AppDrawer extends StatelessWidget {
  final VoidCallback onCurrencyTap;
  final VoidCallback onLengthTap;

  const AppDrawer({
    super.key,
    required this.onCurrencyTap,
    required this.onLengthTap,
  });

  static const orange = Color(0xFFEC8116);
  static const panelColor = Color(0xFF191818);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: panelColor,
      width: 285,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _DrawerItem(
              label: 'Currency',
              icon: Icons.currency_exchange,
              iconSize: 30,
              onTap: onCurrencyTap,
            ),
            const Divider(color: Colors.white24, height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 20),
            _DrawerItem(
              label: 'Length',
              icon: Icons.straighten,
              iconSize: 28,
              onTap: onLengthTap,
            ),
            const Divider(color: Colors.white24, height: 1, indent: 24, endIndent: 24),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppDrawer.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Icon(icon, color: AppDrawer.orange, size: iconSize),
            ],
          ),
        ),
      ),
    );
  }
}