import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'login_and_signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with the correct URL and anon key
  await Supabase.initialize(
    url: 'https://fbofelxkabyqngzbtuuo.supabase.co', // Your actual Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZib2ZlbHhrYWJ5cW5nemJ0dXVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc3NjE0OTgsImV4cCI6MjAzMzMzNzQ5OH0.rexRkyI9f2-wOrqLkTx-tRU1ObpE_CKDOIWtW2hPRk8', // Your actual Supabase anonKey
    authCallbackUrlHostname: 'http://localhost:3000',
  );

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agri-Lenz',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupScreen(),
        '/home': (context) => const HomePage(),
        '/login_signup': (context) => const LoginAndSignupPage(),
      },
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset('lib/assets/logo_final.png'),
              const SizedBox(height: 5),
              Text(
                'Welcome to Agri-Lenz',
                style: GoogleFonts.cardo(
                  textStyle: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Augmenting Agriculture with insight',
                style: GoogleFonts.cardo(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ButtonStyle(
                  textStyle: MaterialStateProperty.all(
                    GoogleFonts.cardo(
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: const Text('Let\'s get started!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
