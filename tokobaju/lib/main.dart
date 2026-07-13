import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Wajib import ini
import 'firebase_options.dart'; // File ini otomatis terbuat dari flutterfire configure
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tokobaju/providers/cart_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  // 1. Pastikan binding Flutter sudah siap sebelum memanggil native code (Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TokoBajuApp());
}

class TokoBajuApp extends StatelessWidget {
  const TokoBajuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        title: 'Toko Baju Ibu IDA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}