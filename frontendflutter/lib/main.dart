import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontendflutter/providers/auth_provider.dart';
import 'package:frontendflutter/core/constants.dart';
import 'package:frontendflutter/core/deep_link_handler.dart';
import 'package:frontendflutter/core/theme.dart';
import 'package:frontendflutter/screens/login_screen.dart';
import 'package:frontendflutter/screens/home_screen.dart';
import 'package:frontendflutter/providers/search_provider.dart';
import 'package:frontendflutter/providers/favorites_provider.dart';
import 'package:frontendflutter/providers/restaurant_detail_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkHandler _deepLinkHandler;

  @override
  void initState() {
    super.initState();
    _deepLinkHandler = DeepLinkHandler(navigatorKey: _navigatorKey);
    _deepLinkHandler.init();
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantDetailProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
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
