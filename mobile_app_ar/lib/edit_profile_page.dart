import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _cellNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Controller for email field
  String _selectedSex = 'Male';
  bool _isLoading = false;
  String? _error;
  File? _selectedImage;
  String? _profileImageUrl;
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _firstNameController.text = widget.userData['first_name'] ?? '';
    _lastNameController.text = widget.userData['last_name'] ?? '';
    _middleInitialController.text = widget.userData['middle_initial'] ?? '';
    _cellNumberController.text = widget.userData['cell_number']?.replaceFirst('+63', '') ?? '';
    _emailController.text = widget.userData['email'] ?? ''; // Initialize email field
    _selectedSex = widget.userData['sex'] ?? 'Male';
    _profileImageUrl = widget.userData['pfp'];

    if (widget.userData['date_of_birth'] != null) {
      _selectedDateOfBirth = DateTime.parse(widget.userData['date_of_birth']);
      _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!);
    }
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
      final uuid = const Uuid().v4();
      final filePath = 'profile/$uuid-$fileName';

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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Step 1: Update the email in Supabase Auth if the email has changed
        if (_emailController.text != widget.userData['email']) {
          final emailResponse = await client.auth.update(
            UserAttributes(email: _emailController.text),
          );

          if (emailResponse.error != null) {
            setState(() {
              _error = 'Error updating email: ${emailResponse.error!.message}';
            });
            return;
          } else {
            // Notify user to verify the new email
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your new email address by clicking the link sent to your email.'),
                duration: Duration(seconds: 3),
              ),
            );
            print('Email updated successfully but pending verification.');
          }
        }

        // Step 2: Upload the profile image if changed
        await _uploadProfileImage();

        // Step 3: Update the profile in the 'profiles' table
        final response = await client
            .from('profiles')
            .update({
              'first_name': _firstNameController.text,
              'last_name': _lastNameController.text,
              'middle_initial': _middleInitialController.text.toUpperCase(),
              'cell_number': '+63${_cellNumberController.text}',
              'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
              'age': _calculateAge(_selectedDateOfBirth!),
              'sex': _selectedSex,
              'pfp': _profileImageUrl,
              'email': _emailController.text, // Save the updated email
            })
            .eq('userId', widget.userData['userId'])
            .execute();

        if (response.error != null) {
          setState(() {
            _error = response.error!.message;
          });
          print('Update error: ${response.error!.message}');
        } else {
          print('Profile updated successfully.');

          // Fetch updated profile data
          final updatedData = {
            'first_name': _firstNameController.text,
            'last_name': _lastNameController.text,
            'middle_initial': _middleInitialController.text,
            'cell_number': '+63${_cellNumberController.text}',
            'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
            'age': _calculateAge(_selectedDateOfBirth!),
            'sex': _selectedSex,
            'pfp': _profileImageUrl,
            'email': _emailController.text,
          };

          // Return updated profile data to the previous screen
          Navigator.pop(context, updatedData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully.')),
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

  Future<void> _changePassword() async {
    Navigator.pushNamed(context, '/change-password'); // Navigate to Change Password screen
  }

  Future<void> _changeEmail() async {
    Navigator.pushNamed(context, '/change-email'); // Navigate to Change Email screen
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
        borderSide: const BorderSide(color: Colors.green),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration('First Name'),
                  enabled: false, // Make First Name read-only
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Last Name'),
                  enabled: false, // Make Last Name read-only
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _middleInitialController,
                  decoration: _inputDecoration('Middle Initial'),
                  enabled: false, // Make Middle Initial read-only
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cellNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Cell Number',
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SvgPicture.asset(
                            'lib/assets/Ph_flag.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text(
                            '+63',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      ],
                    ),
                  ),
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.length != 10) {
                      return 'Please enter a valid cell number (Philippine number only)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('Email'), // Email field
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateOfBirthController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration('Date of Birth', suffixIcon: const Icon(Icons.calendar_today)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your date of birth';
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
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _changePassword, // Button to change password
                  child: const Text('Change Password'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _changeEmail, // Button to change email
                  child: const Text('Change Email'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text('Error: $_error', style: const TextStyle(color: Colors.red)),
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
