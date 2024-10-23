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
        '/': (context) => StartupScreen(),
        '/home': (context) => HomePage(),
        '/login_signup': (context) => LoginAndSignupPage()
      },
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late ColorTween _backgroundColorTween;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _backgroundColorTween = ColorTween(
      begin: const Color(0xFF50C878),
      end: const Color(0xFFe8F5E9),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(seconds: 3),
            color: _backgroundColorTween.evaluate(_controller),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Image.asset('lib/assets/logo_final.png'),
                    ),
                    const SizedBox(height: 5),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Welcome to Agri-Lenz',
                        style: GoogleFonts.cardo(
                          textStyle: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Augmenting Agriculture with insight',
                        style: GoogleFonts.cardo(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ElevatedButton(
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
