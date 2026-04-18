import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/app/router.dart';
import 'package:nfc_reader_writer/app/theme.dart';

/// Root widget aplikasi.
///
/// Mengkonfigurasi [MaterialApp.router] dengan tema terang/gelap
/// dan router yang sudah berisi dependency injection.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'NFC Reader Writer',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    routerConfig: buildAppRouter(),
  );
}
