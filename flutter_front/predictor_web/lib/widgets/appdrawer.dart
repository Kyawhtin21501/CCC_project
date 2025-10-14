import 'package:flutter/material.dart';
import 'package:predictor_web/screens/create_shift.dart';
import 'package:predictor_web/screens/daily_report.dart';
import 'package:predictor_web/screens/shift_auto_generate.dart';

import 'package:predictor_web/screens/staff_profile.dart' hide CreatedShiftScreen;



class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('メニュー', style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('ダッシュボード'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('シフト作成'),
            onTap: () {
              Navigator.pop(context);
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShiftAutoScreen()
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_history),
            title: const Text('シフト希望登録'),
           onTap: () {
              Navigator.pop(context);
             Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreatedShiftScreen(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_box_outlined),
            title: const Text('新規スタッフ登録'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>StaffProfileScreen() ),
              );
            },
          ),
        ],
      ),
    );
  }
}

