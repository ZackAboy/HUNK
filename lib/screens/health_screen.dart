import 'package:flutter/material.dart';

import '../widgets/placeholder_panel.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        PlaceholderPanel(
          icon: Icons.favorite_border,
          title: 'Health data sources',
          body:
              'Apple HealthKit on iOS and Google Health Connect on Android will connect here. No real health integration is active yet.',
        ),
        SizedBox(height: 12),
        PlaceholderPanel(
          icon: Icons.summarize_outlined,
          title: 'Basic health summary',
          body:
              'This screen will eventually summarize metrics such as sleep, activity, workouts, and recovery signals.',
        ),
      ],
    );
  }
}
