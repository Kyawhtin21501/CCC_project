import 'package:flutter/material.dart';
import 'package:predictor_web/screens/daily_report.dart';

import 'package:predictor_web/screens/create_shift.dart';
import 'package:predictor_web/screens/shift_auto_generate.dart';
import 'package:predictor_web/screens/staff_profile.dart' ;

enum DrawerScreen { dashboard, shiftCreate, shiftRequest, staffProfile }

class AppDrawer extends StatelessWidget {
  final DrawerScreen currentScreen;

  const AppDrawer({super.key, required this.currentScreen});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'メニュー',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.dashboard,
            title: 'ダッシュボード',
            screen: DrawerScreen.dashboard,
            destination: const DashboardScreen(),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.trending_up,
            title: 'シフト作成',
            screen: DrawerScreen.shiftCreate,
            destination: const ShiftAutoScreen(),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.work_history,
            title: 'シフト希望登録',
            screen: DrawerScreen.shiftRequest,
            destination: const CreatedShiftScreen(),
          ),
          _buildDrawerTile(
            context,
            icon: Icons.account_box_outlined,
            title: '新規スタッフ登録',
            screen: DrawerScreen.staffProfile,
            destination: const StaffProfileScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(BuildContext context,
      {required IconData icon,
      required String title,
      required DrawerScreen screen,
      required Widget destination}) {
    final bool isSelected = currentScreen == screen;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        } else {
          Navigator.pop(context); // just close drawer if already selected
        }
      },
    );
  }
}
