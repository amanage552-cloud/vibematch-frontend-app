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
          primaryColor: Colors.pink,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
