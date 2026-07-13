import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tokobaju/screens/login_screen.dart';

void main() {
  runApp(const TokoBajuApp());
}

class TokoBajuApp extends StatelessWidget {
  const TokoBajuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Baju COD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E232A)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}