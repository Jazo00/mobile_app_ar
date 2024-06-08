import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginAndSignupPage extends StatefulWidget {
  @override
  _LoginAndSignupPageState createState() => _LoginAndSignupPageState();
}

class _LoginAndSignupPageState extends State<LoginAndSignupPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cellNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedSex = 'Male';

  void toggleFormType() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final response = await _supabaseClient.auth.signUp(
        _emailController.text,
        _passwordController.text,
      );
      if (response.error == null) {
        await _supabaseClient.from('profiles').insert({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'middle_initial': _middleInitialController.text,
          'email': _emailController.text,
          'cell_number': _cellNumberController.text,
          'age': int.parse(_ageController.text),
          'sex': _selectedSex,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up successful! Please log in')),
        );
        setState(() {
          isLogin = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error!.message)),
        );
      }
    }
  }

  Future<void> _login() async {
    final response = await _supabaseClient.auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (response.error == null) {
      Navigator.pushNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error!.message)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!isLogin) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'First Name'),
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
                  decoration: InputDecoration(labelText: 'Last Name'),
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
                  decoration: InputDecoration(labelText: 'Middle Initial'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cellNumberController,
                  decoration: InputDecoration(labelText: 'Cell Number'),
                  validator: (value) {
                    if (value == null || !RegExp(r'^\+63\d{10}$').hasMatch(value)) {
                      return 'Please enter a valid cell number (e.g., +639123456789)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || !RegExp(r'^\d{2}$').hasMatch(value)) {
                      return 'Please enter a valid age (2 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  decoration: InputDecoration(labelText: 'Sex'),
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
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || !RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                    return 'Password must be at least 8 characters long, include an uppercase letter, a number, and a special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: isLogin ? _login : _signUp,
                  child: Text(isLogin ? 'Login' : 'Sign Up'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: toggleFormType,
                  child: Text(
                    isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
