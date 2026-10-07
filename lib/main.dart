import 'package:flutter/material.dart';

import 'screens/session_gate.dart';
import 'services/energy_api_client.dart';
import 'services/session_storage.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SmartEnergyApp());
}

class SmartEnergyApp extends StatelessWidget {
  const SmartEnergyApp({
    this.api,
    this.sessionStorage,
    super.key,
  });

  final EnergyApiClient? api;
  final SessionStorage? sessionStorage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Energy Tanzania',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SessionGate(
        api: api ?? EnergyApiClient(),
        sessionStorage: sessionStorage ?? const SecureSessionStorage(),
      ),
    );
  }
}
