// File: home_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'livestock_info.dart';
import 'user_profile_page.dart';
import 'login_and_signup_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String? userId;

  static const List<String> _titles = <String>[
    'Maligayang pagdating sa Agri-Lenz',
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
          title: const Text('Kailangan mag-log-in'),
          content: const Text('Mangyaring mag-login o lumikha ng account upang magamit ang tampok na ito.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Mag-Login'),
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
              child: const Text('Icancel'),
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
        return HomePageContent(
          onLogin: () => _showLoginPrompt(),
          isLoggedIn: _isLoggedIn,
        );
      case 1:
        return LivestockInfoPage();
      case 2:
        if (userId != null) {
          return UserProfilePage(isLoggedIn: _isLoggedIn, userId: userId!);
        } else {
          return const Center(
            child: Text('User ID is null. Please log in again.'),
          );
        }
      default:
        return HomePageContent(
          onLogin: () => _showLoginPrompt(),
          isLoggedIn: _isLoggedIn,
        );
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
            child: const Text('Mag-Login'),
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  final VoidCallback onLogin;
  final bool isLoggedIn;

  const HomePageContent({super.key, required this.onLogin, required this.isLoggedIn});

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
              'Ano ang Augmented Reality?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ang Augmented Reality (AR) ay isang interaktibong karanasan kung saan ang digital na impormasyon ay idinadagdag sa totoong mundo. Maaaring maranasan ang AR gamit ang iba’t ibang mga device, tulad ng mga smartphone at tablet.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tungkol sa Aming Sistema',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pinapahusay ng kakayahang AR ang karanasan ng gumagamit sa pamamagitan ng pagdaragdag ng digital na impormasyon sa totoong mundo, na nagbibigay ng makabuluhang impormasyon tungkol sa mga hayop sa isang nakakaengganyong paraan. Maaaring kabilang sa tampok na ito ang impormasyon tungkol sa mga lahi ng hayop, pangangalaga, pagpapakain, at iba pang mga paksa. Pinagsasama ng aming sistema ang teknolohiyang AR sa isang sistema ng impormasyon para sa mga hayop. Maaaring makita ng mga gumagamit ang tiyak at detalyadong impormasyon ng hayop sa AR. ',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!isLoggedIn)
              ElevatedButton(
                onPressed: onLogin,
                child: const Text('Mag-Login'),
              ),
          ],
        ),
      ),
    );
  }
}
