import 'package:flutter/material.dart';
import 'package:frontendflutter/core/constants.dart';
import 'package:frontendflutter/core/theme.dart';
import 'package:frontendflutter/screens/login_screen.dart';
import 'package:frontendflutter/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.loginRoute,
      routes: {
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.mapRoute: (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
