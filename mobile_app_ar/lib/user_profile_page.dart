import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // For Clipboard functionality

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

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _error = 'No internet connection. Data will refresh when reconnected.';
          _isLoading = false;
          userData.clear(); 
        });
      } else if (_error != null) {
        _checkInternetAndInitializeUserId();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInternetAndInitializeUserId() async {
    setState(() {
      _isLoading = true;
      _error = null;  
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
        await _fetchUserData(); 
      } else {
        setState(() {
          _isLoading = false;
          _error = "User ID could not be initialized. Please log in again.";
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize User ID. Error: $e';
        _isLoading = false;
      });
    }
  }

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
        userData['userId'] = _userId; 
        _isLoading = false;
        _error = null; 
      });

    } catch (e) {
      setState(() {
        _error = 'Failed to fetch user data. Error: $e';
        _isLoading = false;
      });
    }
  }

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
                        color: Colors.black, 
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
                          const SizedBox.shrink(), 
                          _buildLogoutButton(), 
                        ],
                      ),
                      const SizedBox(height: 20), 
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
        _buildUserInfoTile('Unang Pangalan', userData['first_name']),
        _buildUserInfoTile('Apelyido', userData['last_name']),
        _buildUserInfoTile('Panggitnang Pangalan', userData['middle_initial']),
        _buildUserInfoTile('Email', userData['email']),
        _buildUserInfoTile('Cellphone Number', userData['cell_number']),
        _buildUserInfoTile('Edad', userData['age']),
        _buildUserInfoTile('Kasarian', userData['sex']),
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

  /// Build the Edit Profile Button with a copy-to-clipboard functionality
  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Iedit ang profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      ' Kopyahin at ilagay ang link na ito sa inyong browser \n Maaari mong i-edit ang iyong profile sa susunod na link:'),
                  const SizedBox(height: 10),
                  const SelectableText(
                      'https://mango-stone-046047b10.5.azurestaticapps.net/login'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                          text:
                              'https://mango-stone-046047b10.5.azurestaticapps.net/login'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nakopya ang link'),
                        ),
                      );
                    },
                    child: const Text('Kopyahin ang link'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); 
                  },
                  child: const Text('Iclose'),
                ),
              ],
            );
          },
        );
      },
      child: const Text('Iedit Profile'),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout, 
      child: const Text('Mag-Logout'),
    );
  }
}
