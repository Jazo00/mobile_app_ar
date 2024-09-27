import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeEmailPage extends StatefulWidget {
  @override
  _ChangeEmailPageState createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController _currentEmailController = TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  // Load current email into the form
  void _loadCurrentEmail() async {
    final currentUser = client.auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentEmailController.text = currentUser.email!;
      });
    }
  }

  Future<void> _changeEmail() async {
    if (_newEmailController.text.isEmpty || !_validateEmail(_newEmailController.text)) {
      setState(() {
        _error = 'Please enter a valid new email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await client.auth.update(
        UserAttributes(email: _newEmailController.text),
      );

      if (response.error != null) {
        setState(() {
          _error = response.error!.message;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your new email by clicking the link sent to your email.'),
          ),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to update email: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Basic email validation
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _currentEmailController,
              decoration: const InputDecoration(labelText: 'Current Email'),
              readOnly: true, // Prevent modification of current email
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _newEmailController,
              decoration: const InputDecoration(labelText: 'New Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !_validateEmail(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _changeEmail,
                    child: const Text('Change Email'),
                  ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
