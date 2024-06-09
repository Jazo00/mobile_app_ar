import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SupabaseClient client = Supabase.instance.client;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final response = await client
        .from('profiles')
        .select()
        .eq('userId', widget.userId)
        .single()
        .execute();
    if (response.error == null) {
      setState(() {
        userData = response.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileImage(),
                  SizedBox(height: 20),
                  _buildUserInfo(),
                  SizedBox(height: 20),
                  _buildEditProfileButton(),
                  _buildChangeNumberButton(),
                  _buildChangeEmailButton(),
                  _buildChangePasswordButton(),
                  _buildSaveChangesButton(),
                ],
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
        TextButton(
          onPressed: _changeProfileImage,
          child: Text('Change Profile'),
        ),
      ],
    );
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    final fileName = pickedFile.path.split('/').last;
    final response = await client.storage
        .from('profile-images')
        .uploadBinary(fileName, bytes);
    if (response.error == null) {
      final imageUrl = client.storage.from('profile-images').getPublicUrl(fileName).data;
      await client.from('profiles').update({'profile_image': imageUrl}).eq('userId', widget.userId).execute();
      _fetchUserData();
    }
  }
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
    final noChanges = true; // Add logic to check if no changes were made
    if (noChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('There are no changes made.')),
      );
    } else {
      // Save changes to Supabase
    }
  }
}
