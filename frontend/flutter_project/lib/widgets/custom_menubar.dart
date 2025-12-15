import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:predictor_web/theme_provider/them.dart';

/// A custom app bar/menu bar component used across the application.
/// It features the title, a menu button to open the drawer, and a theme toggle button.
class CustomMenuBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final String title;

  const CustomMenuBar({
    super.key,
    required this.onMenuPressed,
    this.title = 'Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to get theme state and the toggle method.
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDarkMode = themeProvider?.themeMode == ThemeMode.dark;

    // Use Theme colors for a clean, consistent look.
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    
    // For the Menu Bar background, we will use the AppBar's background color 
    // which is defined in your custom themes (Light: Deep Ocean, Dark: Mid Navy).
    final Color menuBarColor = Theme.of(context).appBarTheme.backgroundColor ?? primaryColor;


    return Material(
      // Use elevation 0, as the `Positioned` widget in DashboardScreen
      // already gives it a lift from the main content.
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      // Use the AppBar's defined background color for the menu bar
      color: menuBarColor, 
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Menu Button (Always use the `onPrimary` color for icons/text on the menu bar)
            IconButton(
              icon: Icon(Icons.menu, color: onPrimaryColor),
              onPressed: onMenuPressed,
            ),

            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: onPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: onPrimaryColor, // Use the onPrimary color
              ),
              // Toggle logic is corrected to pass the intended new state (Light Mode if currently dark, and vice versa)
              onPressed: () => themeProvider?.toggleTheme(!isDarkMode), 
            ),
          ],
        ),
      ),
    );
  }
}