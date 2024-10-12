import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfilePage extends StatefulWidget {
  final bool isLoggedIn;
  final String userId;

  const UserProfilePage({super.key, required this.isLoggedIn, required this.userId});

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

          // Ensure userId is set in userData
          userData['userId'] = widget.userId;

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
    
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logged Out'),
          content: const Text('Account logged out. You will now be redirected to the Home page.'),
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
  }

  Future<void> _navigateToEditProfile() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: const Text('To edit your profile, you must use the website version of the app. You will now be redirected to the AgriLenz Website.'),
          actions: [
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://youtube.com'); // Replace with the actual URL
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch the website')),
                  );
                }
              },
              child: const Text('Proceed'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog if the user cancels
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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
      onPressed: _navigateToEditProfile,
      child: const Text('Edit Profile'),
    );
  }
}
