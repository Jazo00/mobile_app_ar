import 'package:flutter/material.dart';
import 'login_and_signup_page.dart'; // Import your login and signup page file

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;

  static const List<String> _titles = <String>[
    'Home',
    'Livestock Information',
    'Marketplace',
    'Account'
  ];

  void _onItemTapped(int index) {
    if (index == 2 || index == 3) {
      // Marketplace and Account require login
      if (!_isLoggedIn) {
        _showLoginPrompt();
        return;
      }
    }
    setState(() {
      _selectedIndex = index;
    });
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
                // Navigate to login_and_signup_page.dart
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginAndSignupPage()), // Navigate to your login and signup page
                );
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

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Agri-Lenz',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Our system provides valuable insights to augment agriculture. Our purpose is to assist farmers and agricultural businesses with data-driven solutions.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: () => _onItemTapped(2),
              child: const Text('View Marketplace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivestockInformation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Livestock Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'We provide detailed information about various livestock. Currently, we have information about chickens, including their care, feeding, and health management.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Login to Continue',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to actual login screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginAndSignupPage()), // Navigate to your login and signup page
              );
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplace() {
    return Center(
      child: Text(
        'Marketplace',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildAccountDetails() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Account Details',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          Text(
            'User: John Doe',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            'Email: johndoe@example.com',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle logout
              setState(() {
                _isLoggedIn = false;
                _selectedIndex = 0;
              });
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      _buildHomeContent(),
      _buildLivestockInformation(),
      _isLoggedIn ? _buildMarketplace() : _buildLoginScreen(),
      _isLoggedIn ? _buildAccountDetails() : _buildLoginScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
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
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
