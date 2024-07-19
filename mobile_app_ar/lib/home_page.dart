// File: home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'livestock_info.dart';
import 'user_profile_page.dart';
import 'login_and_signup_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String? userId;

  static const List<String> _titles = <String>[
    'Welcome to Agri-Lenz',
    'Livestock Information',
    'Account'
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadUserId();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  void _onItemTapped(int index) {
    if ((index == 1 || index == 2) && !_isLoggedIn) {
      _showLoginPrompt();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Required'),
          content: Text('Please login or create an account to access this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginAndSignupPage()),
                ).then((value) {
                  _checkLoginStatus().then((_) {
                    _loadUserId().then((_) {
                      if (_isLoggedIn) {
                        setState(() {
                          _selectedIndex = 0; // Navigate to homepage after login
                        });
                      }
                    });
                  });
                });
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePageContent(onLogin: () => _showLoginPrompt());
      case 1:
        return LivestockInfoPage();
      case 2:
        if (userId != null) {
          return UserProfilePage(isLoggedIn: _isLoggedIn, userId: userId!);
        } else {
          return Center(
            child: Text('User ID is null. Please log in again.'),
          );
        }
      default:
        return HomePageContent(onLogin: () => _showLoginPrompt());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _isLoggedIn || _selectedIndex == 0
          ? _getPage(_selectedIndex)
          : _buildLoginScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Livestock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Login to Continue',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginAndSignupPage()),
              ).then((value) {
                _checkLoginStatus().then((_) {
                  _loadUserId().then((_) {
                    if (_isLoggedIn) {
                      setState(() {
                        _selectedIndex = 0; // Navigate to homepage after login
                      });
                    }
                  });
                });
              });
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final VoidCallback onLogin;

  HomePageContent({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Image.asset(
                  'lib/assets/logo_final.png',
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What is Augmented Reality?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Augmented Reality (AR) is an interactive experience where digital information is overlaid onto the real world. AR can be experienced through various devices, including smartphones, tablets, and AR glasses.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'About Our System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'The AR capability enhances user experience by overlaying digital information on the real world, providing informative content about livestock in an interactive and engaging way. This feature could include information about livestock breeds, care, feeding, and other relevant topics. Our system combines augmented reality (AR) technology with an information system for livestock and a marketplace for listing livestock for sale. Users can view livestock information in AR, access informative resources about livestock, and list livestock for sale. Transactions are not handled by the system; users manage transactions independently, and the system allows them to mark livestock as available for sale.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
