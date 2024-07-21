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
          TextButton(
            onPressed: _logout,
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _buildProfileImage()),
                      SizedBox(height: 20),
                      _buildUserInfo(),
                      SizedBox(height: 20),
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
      child: userData['pfp'] == null
          ? Icon(Icons.person, size: 50)
          : null,
      backgroundColor: Colors.grey.shade200,
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
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value?.toString() ?? 'N/A'),
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: _navigateToEditProfile,
      child: Text('Edit Profile'),
    );
  }
}
