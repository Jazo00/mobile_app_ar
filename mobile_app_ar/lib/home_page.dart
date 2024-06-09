import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'livestock_info.dart';
import 'marketplace.dart';
import 'user_profile_page.dart';
import 'login_and_signup_page.dart';
import 'post_listing_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String? userId;

  static const List<String> _titles = <String>[
    'Livestock Information',
    'Marketplace',
    'Post Listing',
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
    if ((index == 2 || index == 3 || index == 4) && !_isLoggedIn) {
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
                  _checkLoginStatus();
                  _loadUserId();
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
        return HomePageContent(onViewMarketplace: () => _onItemTapped(2));
      case 1:
        return LivestockInfoPage();
      case 2:
        return MarketplacePage();
      case 3:
        return PostListingPage();
      case 4:
        if (userId != null) {
          return UserProfilePage(userId: userId!);
        } else {
          return Center(
            child: Text('User ID is null. Please log in again.'),
          );
        }
      default:
        return HomePageContent(onViewMarketplace: () => _onItemTapped(2));
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
      body: _isLoggedIn || _selectedIndex == 0 || _selectedIndex == 1
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
            icon: Icon(Icons.shopping_cart),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Post Listing',
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
                _checkLoginStatus();
                _loadUserId();
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
  final VoidCallback onViewMarketplace;

  HomePageContent({required this.onViewMarketplace});

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
              onPressed: onViewMarketplace,
              child: Text('View Marketplace'),
            ),
          ],
        ),
      ),
    );
  }
}
