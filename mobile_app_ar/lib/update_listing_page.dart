import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UpdateListingPage extends StatefulWidget {
  final Map<String, dynamic> listing;

  UpdateListingPage({required this.listing});

  @override
  _UpdateListingPageState createState() => _UpdateListingPageState();
}

class _UpdateListingPageState extends State<UpdateListingPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController imageController;
  File? _image;
  String? _imageUrl;
  String? _error;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing['listing_title']);
    _descriptionController = TextEditingController(text: widget.listing['listing_description']);
    _priceController = TextEditingController(text: widget.listing['listing_price'].toString());
    _imageUrl = widget.listing['listing_image'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) {
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

      // Validate the price
      final int? price = int.tryParse(_priceController.text);
      if (price == null) {
        throw Exception('Invalid price format');
      }

      // Validate the listing ID
      final String listingId = widget.listing['listing_id'];
      if (listingId.isEmpty) {
        throw Exception('Invalid listing ID');
      }

      // Validate the user ID
      final String userId = widget.listing['user_id'];
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      String? imageUrl = _imageUrl;
      if (_image != null) {
        final imageResponse = await _supabaseClient.storage
            .from('listings')
            .upload('public/${DateTime.now().millisecondsSinceEpoch}.jpg', _image!);

        if (imageResponse.error != null) {
          print('Image upload error: ${imageResponse.error!.message}');
          throw imageResponse.error!;
        }

        imageUrl = 'https://fbofelxkabyqngzbtuuo.supabase.co/storage/v1/object/public/${imageResponse.data!}';
        print('Image uploaded: $imageUrl');
      }

      // Detailed logging before making the RPC call
      print('Calling update_listing with parameters:');
      print('p_listing_id: $listingId');
      print('p_listing_title: ${_titleController.text}');
      print('p_listing_description: ${_descriptionController.text}');
      print('p_listing_price: $price');
      print('p_listing_image: $imageUrl');
      print('p_user_id: $userId');

      final response = await _supabaseClient
          .rpc('update_listing', params: {
            'p_listing_id': listingId,
            'p_listing_title': _titleController.text,
            'p_listing_description': _descriptionController.text,
            'p_listing_price': price,
            'p_listing_image': imageUrl,
            'p_user_id': userId
          })
          .execute();

      // Detailed logging after making the RPC call
      print("RPC call status: ${response.status}");
      print("RPC call error: ${response.error?.message}");
      print("RPC call data: ${response.data}");

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      if (response.status == 204 || (response.data != null && response.status == 200)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing updated successfully')));
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'Failed to update listing. Status code: ${response.status}';
        });
      }
    } catch (error) {
      print("Error updating listing: $error");
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
        title: Text('Update Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _image == null
                    ? _imageUrl == null
                        ? Text('No image selected.')
                        : Image.network(_imageUrl!, height: 200)
                    : Image.file(_image!, height: 200),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Pick Image'),
                ),
                SizedBox(height: 16),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _updateListing,
                        child: Text('Update Listing'),
                      ),
                if (_error != null) ...[
                  SizedBox(height: 16),
                  Text('Error: $_error', style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
