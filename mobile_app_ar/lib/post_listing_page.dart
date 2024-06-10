// File: post_listing_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PostListingPage extends StatefulWidget {
  @override
  _PostListingPageState createState() => _PostListingPageState();
}

class _PostListingPageState extends State<PostListingPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _postListing() async {
    if (_titleController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _priceController.text.isEmpty || 
        _image == null) {
      setState(() {
        _error = 'All fields are required, including the image.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated.';
        });
        return;
      }
      final userEmail = user.email;
      print('Authenticated user email: $userEmail');

      // Fetch the user profile based on email
      final profileResponse = await _supabaseClient
          .from('profiles')
          .select('userId')
          .eq('email', userEmail)
          .single()
          .execute();

      if (profileResponse.error != null) {
        setState(() {
          _error = 'Error fetching user profile: ${profileResponse.error!.message}';
        });
        return;
      }

      if (profileResponse.data == null) {
        setState(() {
          _error = 'User profile not found.';
        });
        return;
      }

      final userId = profileResponse.data['userId'];
      print('User ID from profiles table: $userId');

      final imageResponse = await _supabaseClient.storage
          .from('listings')
          .upload('public/${DateTime.now().millisecondsSinceEpoch}.jpg', _image!);

      if (imageResponse.error != null) {
        print('Image upload error: ${imageResponse.error!.message}');
        throw imageResponse.error!;
      }

      final imageUrl = _supabaseClient.storage.from('listings').getPublicUrl(imageResponse.data!).data!;
      print('Image uploaded: $imageUrl');

      final response = await _supabaseClient
          .from('listing')
          .insert({
            'listing_title': _titleController.text,
            'listing_description': _descriptionController.text,
            'listing_price': int.parse(_priceController.text), // Parse price as integer
            'listing_image': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'user_id': userId, // Use the profile ID here
          })
          .execute();

      if (response.error != null) {
        print('Insert error: ${response.error!.message}');
        throw response.error!;
      }

      print('Insert response: ${response.data}');
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      setState(() {
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing posted successfully!')));
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
      print('Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(2.0), 
        child: AppBar(
          automaticallyImplyLeading: false,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!, height: 200),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _postListing,
                      child: Text('Post Listing'),
                    ),
              if (_error != null) ...[
                SizedBox(height: 16),
                Text('Error: $_error', style: TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
