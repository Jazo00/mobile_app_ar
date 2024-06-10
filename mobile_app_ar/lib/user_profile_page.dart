import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
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
                        SizedBox(height: 10),
                        _buildChangeNumberButton(),
                        SizedBox(height: 10),
                        _buildChangeEmailButton(),
                        SizedBox(height: 10),
                        _buildChangePasswordButton(),
                        SizedBox(height: 10),
                        _buildSaveChangesButton(),
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
          backgroundImage: userData['profile_image'] != null
              ? NetworkImage(userData['profile_image'])
              : null,
          child: userData['profile_image'] == null
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
      onPressed: () {
        // Navigate to edit profile page
      },
      child: Text('Edit Profile'),
    );
  }

  Widget _buildChangeNumberButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to change number page
      },
      child: Text('Change Number'),
    );
  }

  Widget _buildChangeEmailButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to change email page
      },
      child: Text('Change Email'),
    );
  }

  Widget _buildChangePasswordButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate to change password page
      },
      child: Text('Change Password'),
    );
  }

  Widget _buildSaveChangesButton() {
    return ElevatedButton(
      onPressed: _saveChanges,
      child: Text('Save Changes'),
    );
  }

  Future<void> _saveChanges() async {
    // Check for changes and save to Supabase
    final bool changesMade = true; // Add your logic to detect changes
    if (changesMade) {
      // Save changes to Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes saved successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('There are no changes made.')),
      );
    }
  }
}
