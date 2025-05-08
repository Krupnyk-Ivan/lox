import 'package:flutter/material.dart';
import 'package:lox/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'services/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/add_advertisement_screen.dart';
import './screens/analytics_screen.dart';
import './screens/all_advertisements_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad Portal',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
      routes: {
        '/addAdvertisement': (context) => const AddAdvertisementScreen(),
        '/register': (context) => const RegisterScreen(),
        '/stats': (context) => const AnalyticsScreen(),
        '/d': (context) => const AllAdvertisementsScreen(),
      },
    );
  }
}
