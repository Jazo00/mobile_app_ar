import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // For retry mechanism

class UserProfilePage extends StatefulWidget {
  final bool isLoggedIn;
  final String? userId; 

  const UserProfilePage({super.key, required this.isLoggedIn, this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseClient client = Supabase.instance.client;
  Map<String, dynamic> userData = {};
  bool _isLoading = true;
  String? _error;
  String? _userId;
  int _retryCount = 0;  // To handle retries

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  /// Initialize the User ID from either widget or SharedPreferences
  Future<void> _initializeUserId() async {
    try {
      print('Initializing UserId...');
      if (widget.userId != null) {
        setState(() {
          _userId = widget.userId;
          print('UserId from widget: $_userId');
        });
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? storedUserId = prefs.getString('userId');
        print('Stored userId from SharedPreferences: $storedUserId');
        
        if (storedUserId != null) {
          setState(() {
            _userId = storedUserId;
          });
        } else {
          print('UserId not found in SharedPreferences. Logging out.');
          _logout();
          return;
        }
      }

      // Ensure we have a valid userId before fetching data
      if (_userId != null) {
        await _fetchUserDataWithRetry();  // Retry mechanism for fetching data
      } else {
        setState(() {
          _isLoading = false;
          _error = "User ID could not be initialized.";
          print('Error: User ID is null.');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize User ID. Error: $e';
        _isLoading = false;
      });
      print('Error initializing User ID: $e');
    }
  }

  /// Fetch user data with retries
  Future<void> _fetchUserDataWithRetry() async {
    const int maxRetries = 3;
    while (_retryCount < maxRetries) {
      try {
        await _fetchUserData();
        if (_error == null) {
          return;  // Exit retry loop if successful
        }
      } catch (e) {
        print('Retry #${_retryCount + 1} failed: $e');
      }
      _retryCount++;
      await Future.delayed(Duration(seconds: 2));  // Delay before retrying
    }

    setState(() {
      _error = 'Failed to fetch user data after $maxRetries retries.';
      _isLoading = false;
    });
    print('Exceeded max retries for fetching user data.');
  }

  /// Fetch the user data from Supabase
  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if Supabase current user is authenticated
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated Supabase user found.');
      }

      print('Fetching user profile data for email: ${currentUser.email}');
      final response = await client
          .from('profiles')
          .select()
          .eq('email', currentUser.email)
          .single()
          .execute();

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      setState(() {
        userData = response.data;
        userData['userId'] = _userId;  // Include the userId from state
        _isLoading = false;
      });
      print('User data successfully fetched: $userData');

    } catch (e) {
      setState(() {
        _error = 'Failed to fetch user data. Error: $e';
        _isLoading = false;
      });
      print('Error fetching user data: $e');
      throw e;  // Re-throw error to trigger retry mechanism
    }
  }

  /// Handle logout and clean up stored data
  void _logout() async {
    try {
      await client.auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
      
      showDialog(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logged Out'),
            content: const Text('You have been logged out. Redirecting to the home page.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to log out. Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Profile'),
        actions: [
          TextButton(
            onPressed: _logout,
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _buildProfileImage()),
                      const SizedBox(height: 20),
                      _buildUserInfo(),
                      const SizedBox(height: 20),
                      Center(child: _buildEditProfileButton()),
                    ],
                  ),
                ),
    );
  }

  /// Builds the profile image
  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: userData['pfp'] != null
          ? NetworkImage(userData['pfp'])
          : null,
      backgroundColor: Colors.grey.shade200,
      child: userData['pfp'] == null
          ? Icon(Icons.person, size: 50)
          : null,
    );
  }

  /// Builds the user info cards
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserInfoTile('First Name', userData['first_name']),
        _buildUserInfoTile('Last Name', userData['last_name']),
        _buildUserInfoTile('Middle Initial', userData['middle_initial']),
        _buildUserInfoTile('Email', userData['email']),
        _buildUserInfoTile('Cell Number', userData['cell_number']),
        _buildUserInfoTile('Age', userData['age']),
        _buildUserInfoTile('Sex', userData['sex']),
      ],
    );
  }

  /// Builds a user info tile
  Widget _buildUserInfoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value?.toString() ?? 'N/A'),
      ),
    );
  }

  /// Builds the "Edit Profile" button
  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: () {
        // Add your edit profile logic here
      },
      child: const Text('Edit Profile'),
    );
  }
}
