import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/gestor_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().loadToken();
  final bool isAuthenticated = ApiService().isAuthenticated;
  runApp(MyApp(isAuthenticated: isAuthenticated));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Safe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        textTheme: GoogleFonts.outfitTextTheme(),
        useMaterial3: true,
      ),
      home: isAuthenticated
          ? (ApiService().role == 'gestor'
                ? const GestorHomeScreen()
                : const HomeScreen())
          : const LoginScreen(),
    );
  }
}
