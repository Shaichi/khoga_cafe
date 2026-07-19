import 'package:flutter/material.dart';
import '../theme.dart';
import 'revenue_report_screen.dart';
import 'worked_hours_report_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: const Text('Báo Cáo', style: TextStyle(color: kBrownDark, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: kBrownDark,
          elevation: 0,
          bottom: const TabBar(
            labelColor: kBrownDark,
            unselectedLabelColor: kMuted,
            indicatorColor: kBrownDark,
            tabs: [
              Tab(text: 'Doanh Thu'),
              Tab(text: 'Giờ Công'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RevenueReportScreen(),
            WorkedHoursReportScreen(),
          ],
        ),
      ),
    );
  }
}
