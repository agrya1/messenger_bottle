import 'package:flutter/material.dart';
import 'package:drift_bottle/config/theme.dart';
import 'package:drift_bottle/config/routes.dart';
import 'package:drift_bottle/providers/app_providers.dart';
import 'package:provider/provider.dart';
import 'package:drift_bottle/providers/theme_provider.dart';
import 'package:drift_bottle/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地存储
  await StorageService.init();

  runApp(const AppProviders(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: '漂流瓶',
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: themeProvider.themeMode,
          routerConfig: goRouter,
        );
      },
    );
  }
}
