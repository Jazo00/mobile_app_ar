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
      // Upload image
      final imageResponse = await _supabaseClient.storage
          .from('listings')  // Correct bucket name
          .upload('public/${DateTime.now().millisecondsSinceEpoch}.jpg', _image!);

      if (imageResponse.error != null) {
        throw imageResponse.error!;
      }

      final imageUrl = _supabaseClient.storage.from('listings').getPublicUrl(imageResponse.data!).data!;

      // Insert listing
      final response = await _supabaseClient
          .from('listing')  // Correct table name
          .insert({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'price': double.parse(_priceController.text),
            'image_url': imageUrl,
          })
          .execute();

      if (response.error != null) {
        throw response.error!;
      }

      // Clear form
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a Listing'),
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
