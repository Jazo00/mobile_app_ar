import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'livestock_info.dart'; // Import your livestock_info.dart file
import 'marketplace.dart'; // Import your marketplace.dart file
import 'user_profile_page.dart'; // Import your user_profile_page.dart file
import 'login_and_signup_page.dart'; // Import your login and signup page file
import 'post_listing_page.dart'; // Import your post_listing page file

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String userId = '12345'; // Example user ID
  String livestockId = 'abcde'; // Example livestock ID

  static const List<String> _titles = <String>[
    'Welcome to Agri-Lenz',
    'Livestock Information',
    'Marketplace',
    'Post Listing',
    'Account'
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
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
                  _checkLoginStatus(); // Re-check login status after returning from login page
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
        return LivestockInfoPage(livestockId: livestockId);
      case 2:
        return MarketplacePage();
      case 3:
        return PostListingPage();
      case 4:
        return UserProfilePage(userId: userId);
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
          Text(
            'Login to Continue',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginAndSignupPage()),
              ).then((value) {
                _checkLoginStatus(); // Re-check login status after returning from login page
              });
            },
            child: Text('Login'),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          const Text(
            'What is Augmented Reality?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Augmented Reality (AR) is an interactive experience where digital information is overlaid onto the real world. AR can be experienced through various devices, including smartphones, tablets, and AR glasses.',
            style: TextStyle(fontSize: 16)
          ),
          const SizedBox(height: 20),
          const Text(
            'About Our System',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('The AR capability enhances user experience by overlaying digital information on the real world, providing informative content about livestock in an interactive and engaging way. This feature could include information about livestock breeds, care, feeding, and other relevant topics. Additionally, the information system serves as a platform for informative content delivery, providing users with valuable knowledge about livestock farming practices and management. Our system combines augmented reality (AR) technology with an information system for livestock education and a marketplace for listing livestock for sale. Users can view livestock information in AR, access informative resources about livestock, and list livestock for sale. Transactions are not handled by the system; users manage transactions independently, and the system allows them to mark livestock as available for sale.',
            style: TextStyle(fontSize: 16)
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: onViewMarketplace,
              child: const Text('View Marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
