import 'package:flutter/material.dart';
import 'package:predictor_web/screens/create_shift.dart';
import 'package:predictor_web/screens/daily_report.dart';
import 'package:predictor_web/screens/prediction_result_screen.dart';

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
            decoration: BoxDecoration(color: Color(0xFF2b5797)),
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
          // ListTile(
          //   leading: const Icon(Icons.trending_up),
          //   title: const Text('予測を実行'),
          //   onTap: () {
          //     Navigator.pop(context);
          //    Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => PredictionResultScreen(predictedSales: "predictedSales", predictedStaff: "predictedStaff")),
          //     );
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.work_history),
            title: const Text('シフト作成'),
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
            title: const Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>StaffProfileForm() ),
              );
            },
          ),
        ],
      ),
    );
  }
}

