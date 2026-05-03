import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontendflutter/providers/auth_provider.dart';
import 'package:frontendflutter/core/constants.dart';
import 'package:frontendflutter/core/theme.dart';
import 'package:frontendflutter/screens/login_screen.dart';
import 'package:frontendflutter/screens/home_screen.dart';
import 'package:frontendflutter/providers/search_provider.dart';
import 'package:frontendflutter/providers/favorites_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        initialRoute: AppConstants.loginRoute,
        routes: {
          AppConstants.loginRoute: (context) => const LoginScreen(),
          AppConstants.mapRoute: (context) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
