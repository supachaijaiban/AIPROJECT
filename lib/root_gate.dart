import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'features/approver/approver_dashboard_page.dart';
import 'features/auth/login_page.dart';
import 'features/user/user_dashboard_page.dart';
import 'models/app_user.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = appState.currentUser;
    if (user == null) return const LoginPage();

    return switch (user.role) {
      UserRole.approver || UserRole.admin => const ApproverDashboardPage(),
      UserRole.user => const UserDashboardPage(),
    };
  }
}
