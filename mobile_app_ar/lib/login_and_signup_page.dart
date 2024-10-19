import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';  // Import url_launcher for external redirects

class LoginAndSignupPage extends StatefulWidget {
  const LoginAndSignupPage({super.key});

  @override
  _LoginAndSignupPageState createState() => _LoginAndSignupPageState();
}

class _LoginAndSignupPageState extends State<LoginAndSignupPage> {
  bool isLogin = true;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  late final GotrueSubscription _authStateSubscription;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _middleInitialController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cellNumberController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedSex = 'Male';
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange((event, session) {
      if (event == AuthChangeEvent.signedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.data?.unsubscribe();
    super.dispose();
  }

  void toggleFormType() {
    setState(() {
      isLogin = !isLogin;
    });
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

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must accept the Terms and Conditions')),
        );
        return;
      }

      if (_selectedDateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }

      final int age = _calculateAge(_selectedDateOfBirth!);
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be 18 or above to create an account')),
        );
        return;
      }

      final response = await _supabaseClient.auth.signUp(
        _emailController.text,
        _passwordController.text,
      );

      if (response.error == null) {
        final insertResponse = await _supabaseClient.from('profiles').insert({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'middle_initial': _middleInitialController.text,
          'email': _emailController.text,
          'cell_number': '+63${_cellNumberController.text}',
          'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
          'age': age,
          'sex': _selectedSex,
        }).execute();

        if (insertResponse.error == null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', response.user?.id ?? '');

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sign-up Successful'),
                content: const Text(
                  'A verification email has been sent. You will be redirected to the home screen shortly.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile data: ${insertResponse.error!.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-up failed: ${response.error?.message ?? 'Unknown error'}')),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final response = await _supabaseClient.auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (response.error == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', response.user!.id);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Login Successful'),
              content: const Text('You have successfully logged in. Redirecting to the home menu...'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid login credentials. Please try again.')),
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: const Text(
              'You will be redirected to the password reset page. Do you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _launchForgotPasswordUrl(); // Redirect to the external URL
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchForgotPasswordUrl() async {
    const String forgotPasswordUrl = 'https://mango-stone-046047b10.5.azurestaticapps.net/login';
    if (await canLaunch(forgotPasswordUrl)) {
      await launch(forgotPasswordUrl);
    } else {
      throw 'Could not launch $forgotPasswordUrl';
    }
  }

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
                  decoration: _inputDecoration('First Name'),
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
                  decoration: InputDecoration(
                    labelText: 'Middle Initial',
                    counterText: '',
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
                  ),
                  maxLength: 1,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your middle initial';
                    }
                    return null;
                  },
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
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
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
                decoration: _inputDecoration(
                  'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  if (isLogin) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                  } else {
                    if (value == null || !RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                      return 'Password must be at least 8 characters long, include an \n uppercase letter, a number, and a special character';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!isLogin) ...[
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: _inputDecoration(
                    'Confirm Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (bool? value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Terms and Conditions'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('We are collecting your personal data for the purpose of registration only. By proceeding, you agree to our data privacy terms.'),
                                      const SizedBox(height: 10),
                                      const Text('1. Data Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('We collect your name, email, birthday, and contact information.'),
                                      const SizedBox(height: 10),
                                      const Text('2. Data Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Your data is used for account creation, security, and service updates.'),
                                      const SizedBox(height: 10),
                                      const Text('3. Data Protection:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('We employ encryption and security measures to safeguard your data.'),
                                      const SizedBox(height: 10),
                                      const Text('4. Retention & Rights:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('You can modify or delete your data, and request data deletion when no longer needed.'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text(
                          'I accept the Terms and Conditions',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
              ],
              if (isLogin) ...[
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ],
              TextButton(
                onPressed: toggleFormType,
                child: Text(isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Login'),
              ),
              if (isLogin)
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
