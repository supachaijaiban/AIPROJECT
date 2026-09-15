import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'firebase_options.dart';
import 'root_gate.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
