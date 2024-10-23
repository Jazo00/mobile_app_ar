import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the url_launcher package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // For handling connectivity subscription

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
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetAndInitializeUserId();

    // Listen to connectivity changes and fetch data on reconnection
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _error = 'No internet connection. Data will refresh when reconnected.';
          _isLoading = false;
          userData.clear();  // Clear partial data if loading is interrupted
        });
      } else if (_error != null) {
        _checkInternetAndInitializeUserId();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  /// Check internet connection before initializing User ID and fetching data
  Future<void> _checkInternetAndInitializeUserId() async {
    setState(() {
      _isLoading = true;
      _error = null;  // Clear any previous error when attempting to fetch data
    });

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _error = 'No internet connection. Data will refresh when reconnected.';
        _isLoading = false;
      });
    } else {
      _initializeUserId();
    }
  }

  /// Initialize the User ID from either widget or SharedPreferences
  Future<void> _initializeUserId() async {
    try {
      if (widget.userId != null) {
        setState(() {
          _userId = widget.userId;
        });
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? storedUserId = prefs.getString('userId');

        if (storedUserId != null) {
          setState(() {
            _userId = storedUserId;
          });
        } else {
          _logout();
          return;
        }
      }

      if (_userId != null) {
        await _fetchUserData(); // Fetch user data after initializing the User ID
      } else {
        setState(() {
          _isLoading = false;
          _error = "User ID could not be initialized.";
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize User ID. Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Fetch the user data from Supabase
  Future<void> _fetchUserData() async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated Supabase user found.');
      }

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
        userData['userId'] = _userId; // Include the userId from state
        _isLoading = false;
        _error = null;  // Clear error after successful data load
      });

    } catch (e) {
      setState(() {
        _error = 'Failed to fetch user data. Error: $e';
        _isLoading = false;
      });
      throw e; // Re-throw error to trigger retry mechanism
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

  /// Launch the URL for the web version using Uri and launchUrl
  Future<void> _launchWebVersion() async {
    final Uri url = Uri.parse('https://mango-stone-046047b10.5.azurestaticapps.net/');
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Use an external browser
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black, // Set error message text color to black
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox.shrink(), // Leave space on the left
                          _buildLogoutButton(), // Place logout button on the right
                        ],
                      ),
                      const SizedBox(height: 20), // Space below the logout button
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

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundImage: userData['pfp'] != null
          ? NetworkImage(userData['pfp'])
          : null,
      backgroundColor: Colors.grey.shade200,
      child: userData['pfp'] == null ? Icon(Icons.person, size: 50) : null,
    );
  }

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

  Widget _buildUserInfoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value?.toString() ?? 'N/A'),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: const Text('You can edit your profile on our web version. Would you like to proceed?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                    _launchWebVersion(); // Launch the web URL
                  },
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
      child: const Text('Edit Profile'),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout, // Calls the _logout method
      child: const Text('Logout'),
    );
  }
}
