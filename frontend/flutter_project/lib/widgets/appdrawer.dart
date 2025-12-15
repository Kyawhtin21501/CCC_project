import 'package:flutter/material.dart';
// Note: Assuming DashboardScreen is located in daily_report.dart based on original usage context
import 'package:predictor_web/screens/daily_report.dart'; 
import 'package:predictor_web/screens/staff_profile.dart' ;
import 'package:predictor_web/screens/shfit_managment.dart';

/// Enum defining the available screens/destinations in the application drawer.
enum DrawerScreen { dashboard, shiftCreate, shiftRequest, staffProfile, shiftManagement }

/// A custom widget representing the application's navigation drawer.
/// It displays a list of main screens and highlights the current active screen.
class AppDrawer extends StatelessWidget {
  /// The currently active screen, used to highlight the corresponding tile.
  final DrawerScreen currentScreen;

  const AppDrawer({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    // Use the AppBar's theme background color for a consistent header look
    final Color headerColor = Theme.of(context).appBarTheme.backgroundColor ?? primaryColor; 

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Custom Drawer Header styled using the application theme
          Container(
            height: 120, // Reduced height for a compact look
            padding: const EdgeInsets.only(top: 40, left: 16),
            decoration: BoxDecoration(color: headerColor),
            child: Text(
              'メニュー',
              style: TextStyle(
                color: onPrimaryColor, // Text color contrasts with header background
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildDrawerTile(
            context,
            icon: Icons.dashboard_outlined, // Changed icon for a clearer dashboard look
            title: 'ダッシュボード',
            screen: DrawerScreen.dashboard,
            destination: const DashboardScreen(),
          ),
                const Divider(height: 1, thickness: 1),

          _buildDrawerTile(
            context,
            icon: Icons.manage_accounts_outlined,
            title: 'シフト作成・管理',
            screen: DrawerScreen.shiftManagement,
            destination: const ShiftManagementScreen(),
          ),
         
          const Divider(height: 1, thickness: 1),

          _buildDrawerTile(
            context,
            icon: Icons.person_add_alt_1_outlined,
            title: '新規スタッフ登録',
            screen: DrawerScreen.staffProfile,
            destination: const StaffProfileScreen(),
          ),
    
        ],
      ),
    );
  }

  /// Builds a single, themed ListTile for navigation.
  /// It highlights the tile if it corresponds to the [currentScreen].
  Widget _buildDrawerTile(BuildContext context,
      {required IconData icon,
      required String title,
      required DrawerScreen screen,
      required Widget destination}) {
    final bool isSelected = currentScreen == screen;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : onSurfaceColor.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : onSurfaceColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      // Use primary color with low opacity for selection highlight
      tileColor: isSelected ? primaryColor.withOpacity(0.1) : null,
      onTap: () {
        if (!isSelected) {
          // Close the drawer before navigating
          Navigator.pop(context); 
          // Use pushReplacement to prevent building up the navigation stack
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        } else {
          // If already selected, just close the drawer
          Navigator.pop(context); 
        }
      },
    );
  }
}