import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _cellNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedSex = 'Male';
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.userData['first_name'] ?? '';
    _lastNameController.text = widget.userData['last_name'] ?? '';
    _middleInitialController.text = widget.userData['middle_initial'] ?? '';
    _cellNumberController.text = widget.userData['cell_number'] ?? '';
    _ageController.text = widget.userData['age']?.toString() ?? ''; // Convert to string
    _selectedSex = widget.userData['sex'] ?? 'Male';
    _profileImageUrl = widget.userData['pfp'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.path.split('/').last;
      final uuid = Uuid().v4(); // Generate a unique identifier
      final filePath = 'profile/$uuid-$fileName'; // Use the unique identifier in the file path

      final response = await client.storage
          .from('profile')
          .uploadBinary(filePath, bytes);

      if (response.error == null) {
        final urlResponse = client.storage
            .from('profile')
            .getPublicUrl(filePath);
        _profileImageUrl = urlResponse.data;
      } else {
        setState(() {
          _error = response.error!.message;
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await _uploadProfileImage();
        final response = await client
            .from('profiles')
            .update({
              'first_name': _firstNameController.text,
              'last_name': _lastNameController.text,
              'middle_initial': _middleInitialController.text.toUpperCase(),
              'cell_number': _cellNumberController.text,
              'age': int.parse(_ageController.text), // Convert back to integer
              'sex': _selectedSex,
              'pfp': _profileImageUrl, // Save profile image URL
            })
            .eq('userId', widget.userData['userId']) // Use userId here
            .execute();

        if (response.error != null) {
          setState(() {
            _error = response.error!.message;
          });
          print('Update error: ${response.error!.message}');
        } else {
          print('Update response: ${response.data}');
          Navigator.pop(context, widget.userData..['pfp'] = _profileImageUrl); // Pass updated data back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully.')),
          );
        }
      } catch (error) {
        setState(() {
          _error = error.toString();
        });
        print('Catch error: $error');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  final _formKey = GlobalKey<FormState>();

  InputDecoration _inputDecoration(String labelText, {Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.green),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                    child: _selectedImage == null && _profileImageUrl == null
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration('First Name'),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Last Name'),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _middleInitialController,
                  decoration: _inputDecoration('Middle Initial'),
                  maxLength: 1,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    UpperCaseTextFormatter(),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cellNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Cell Number'),
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.length != 10) {
                      return 'Please enter a valid cell number (10 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: _inputDecoration('Age'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{1,2}$')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty || int.tryParse(value) == null) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  decoration: _inputDecoration('Sex'),
                  items: ['Male', 'Female'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSex = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your sex';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        child: Text('Save Changes'),
                      ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
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

// Custom formatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
