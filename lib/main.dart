import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/match_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MatchProvider>(
      create: (_) => MatchProvider()..init(),
      child: MaterialApp(
        title: 'VibeMatch',
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF8B5CF6),
          scaffoldBackgroundColor: const Color(0xFF060609),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5CF6),
            secondary: Color(0xFFFF007F),
            surface: Color(0xFF0F0F16),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
