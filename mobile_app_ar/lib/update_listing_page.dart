import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _error;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing['listing_title']);
    _descriptionController = TextEditingController(text: widget.listing['listing_description']);
    _priceController = TextEditingController(text: widget.listing['listing_price'].toString());
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
      // Validate the price
      final double? price = double.tryParse(_priceController.text);
      if (price == null) {
        throw Exception('Invalid price format');
      }

      // Validate the listing ID
      final String listingId = widget.listing['listing_id'];
      if (listingId.isEmpty) {
        throw Exception('Invalid listing ID');
      }

      print("Updating listing with ID: $listingId");
      print("Title: ${_titleController.text}");
      print("Description: ${_descriptionController.text}");
      print("Price: $price");

      final response = await _supabaseClient
          .rpc('update_listing', params: {
            'p_listing_id': listingId,
            'p_listing_title': _titleController.text,
            'p_listing_description': _descriptionController.text,
            'p_listing_price': price
          })
          .execute();

      print("Response status: ${response.status}");
      print("Response error: ${response.error?.message}");
      print("Response data: ${response.data}");

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      if (response.status == 204 || (response.data != null && response.status == 200)) {
        print("Update successful, navigating back.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Listing updated successfully')));
        Navigator.pop(context, true);
      } else {
        print("Failed to update listing. Status code: ${response.status}");
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
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              if (_error != null)
                Text('Error: $_error', style: TextStyle(color: Colors.red)),
              if (_isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _updateListing,
                  child: Text('Update Listing'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
