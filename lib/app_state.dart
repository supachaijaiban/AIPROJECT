import 'package:flutter/foundation.dart';

import 'models/app_user.dart';
import 'services/auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService authService;
  AppUser? currentUser;
  bool loading = true;

  AppState(this.authService) {
    authService.authStateChanges.listen((state) async {
      if (state.session == null) {
        currentUser = null;
      } else {
        currentUser = await authService.loadCurrentAppUser();
      }
      loading = false;
      notifyListeners();
    });
  }

  Future<void> refreshCurrentUser() async {
    currentUser = await authService.loadCurrentAppUser();
    notifyListeners();
  }
}
