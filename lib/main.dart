import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'root_gate.dart';
import 'services/auth_service.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  runApp(const WelfareClaimApp());
}

class WelfareClaimApp extends StatelessWidget {
  const WelfareClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(AuthService()),
      child: MaterialApp(
        title: 'ระบบขอเบิกสวัสดิการ',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const RootGate(),
      ),
    );
  }
}
