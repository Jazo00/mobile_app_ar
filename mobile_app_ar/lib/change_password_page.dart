import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // SQL-based current password verification function
 // SQL-based current password verification function
Future<bool> _verifyCurrentPassword(String currentPassword) async {
  // Execute the RPC call and wait for the response
  final response = await _supabaseClient
      .rpc('verify_user_password', params: {'password': currentPassword})
      .execute();  // You need to use execute() to get the result

  if (response.error != null) {
    setState(() {
      _error = 'Error verifying current password: ${response.error!.message}';
    });
    return false;
  }

  return response.data == true;  // Accessing the data from the response
}


  // Password update logic
  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final email = _supabaseClient.auth.currentUser?.email;

        if (email == null) {
          setState(() {
            _error = 'User not authenticated';
          });
          return;
        }

        // Step 1: Verify the old password
        final isPasswordValid = await _verifyCurrentPassword(_oldPasswordController.text);
        if (!isPasswordValid) {
          setState(() {
            _error = 'Incorrect old password';
          });
          return;
        }

        // Step 2: Update the password if old password is correct
        final updateResponse = await _supabaseClient.auth.update(
          UserAttributes(password: _newPasswordController.text),
        );

        if (updateResponse.error != null) {
          setState(() {
            _error = 'Error changing password: ${updateResponse.error!.message}';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
            ),
          );
          Navigator.pop(context);
        }
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
  }

  InputDecoration _inputDecoration(String labelText) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: _inputDecoration('Old Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: _inputDecoration('New Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  } else if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                    return 'Password must be at least 8 characters, include an uppercase letter, a number, and a special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: _inputDecoration('Confirm New Password'),
                validator: (value) {
                  if (value == null || value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _changePassword,
                  child: const Text('Change Password'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
