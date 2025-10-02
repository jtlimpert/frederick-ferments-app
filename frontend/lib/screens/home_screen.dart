import 'package:flutter/material.dart';

import 'inventory_list_screen.dart';
import 'suppliers_screen.dart';

/// Main home screen with adaptive navigation.
///
/// Uses bottom navigation bar on small screens (mobile)
/// and navigation rail on large screens (web/desktop/tablet).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Navigation destinations
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.location_on_outlined),
      selectedIcon: Icon(Icons.location_on),
      label: 'Suppliers',
    ),
  ];

  // Screens for each navigation destination
  static const List<Widget> _screens = [
    InventoryListScreen(showAppBar: false),
    SuppliersScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use side navigation rail for wide screens (web/desktop)
        final bool useNavigationRail = constraints.maxWidth >= 640;

        if (useNavigationRail) {
          return _buildNavigationRailLayout();
        } else {
          return _buildBottomNavigationLayout();
        }
      },
    );
  }

  /// Builds layout with navigation rail (for web/desktop).
  Widget _buildNavigationRailLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Navigation rail on the left
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.science,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: _destinations
                .map(
                  (dest) => NavigationRailDestination(
                    icon: dest.icon,
                    selectedIcon: dest.selectedIcon,
                    label: Text(dest.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content area
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  /// Builds layout with bottom navigation bar (for mobile).
  Widget _buildBottomNavigationLayout() {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
