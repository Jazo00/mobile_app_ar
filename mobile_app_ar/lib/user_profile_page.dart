import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  final bool isLoggedIn;
  final String userId;

  UserProfilePage({required this.isLoggedIn, required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseClient client = Supabase.instance.client;
  Map<String, dynamic> userData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authUserEmail = client.auth.currentUser?.email;
    if (authUserEmail != null) {
      final response = await client
          .from('profiles')
          .select()
          .eq('email', authUserEmail)
          .single()
          .execute();
      if (response.error == null) {
        setState(() {
          userData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error!.message;
          _isLoading = false;
        });
      }
    } else {
      print('No authenticated user found.');
    }
  }

  void _logout() async {
    await client.auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _navigateToEditProfile() async {
    final updatedUserData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userData: userData),
      ),
    );

    if (updatedUserData != null) {
      setState(() {
        userData = updatedUserData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('User Profile'),
        actions: [
          ElevatedButton(
            onPressed: _logout,
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 165, 163, 163), // Button color
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        SizedBox(height: 20),
                        _buildUserInfo(),
                        SizedBox(height: 20),
                        _buildEditProfileButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: userData['pfp'] != null
              ? NetworkImage(userData['pfp'])
              : null,
          child: userData['pfp'] == null
              ? Icon(Icons.person, size: 50)
              : null,
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('First Name: ${userData['first_name']}'),
        Text('Last Name: ${userData['last_name']}'),
        Text('Middle Initial: ${userData['middle_initial']}'),
        Text('Email: ${userData['email']}'),
        Text('Cell Number: ${userData['cell_number']}'),
        Text('Age: ${userData['age']}'),
        Text('Sex: ${userData['sex']}'),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: _navigateToEditProfile,
      child: Text('Edit Profile'),
    );
  }
}
