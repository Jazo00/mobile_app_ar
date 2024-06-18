import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDetailPage extends StatefulWidget {
  final String userId;

  UserProfileDetailPage({required this.userId});

  @override
  _UserProfileDetailPageState createState() => _UserProfileDetailPageState();
}

class _UserProfileDetailPageState extends State<UserProfileDetailPage> {
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
    final response = await client
        .from('profiles')
        .select()
        .eq('userId', widget.userId) // Change 'id' to 'userId'
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
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
}
