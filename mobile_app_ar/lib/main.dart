import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'login_and_signup_page.dart'; // Updated import

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
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
        '/infosys': (context) => InformationSystemPage(),
        '/marketplace': (context) => MarketplacePage(),
        '/livestock': (context) => LivestockManagementPage(),
        '/account': (context) => AccountPage(),
        // Remove the routes for LoginPage and SignupPage
        // '/login': (context) => LoginPage(),
        // '/signup': (context) => SignupPage(),
        '/login_signup': (context) => LoginAndSignupPage(), // Update to LoginAndSignupPage
      },
    );
  }
}

class StartupScreen extends StatefulWidget {
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                          );
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

class InformationSystemPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Information System'),
      ),
      body: Center(
        child: Text('Information System Page - Implement information system content here'),
      ),
    );
  }
}

class MarketplacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
      ),
      body: Center(
        child: Text('Marketplace Page - Implement marketplace content here'),
      ),
    );
  }
}

class LivestockManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Livestock Management'),
      ),
      body: Center(
        child: Text('Livestock Management Page - Implement Livestock Management content here'),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Page'),
      ),
      body: Center(
        child: Text('Account Page - Implement Account content here'),
      ),
    );
  }
}
