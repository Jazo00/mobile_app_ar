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
  String _selectedSex = 'Lalaki';
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
          const SnackBar(content: Text('Kailangan mong tanggapin ang Mga Termino at Kundisyon.')),
        );
        return;
      }

      if (_selectedDateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pumili ng iyong petsa ng kapanganakan.')),
        );
        return;
      }

      final int age = _calculateAge(_selectedDateOfBirth!);
      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kailangan mong maging 18 taong gulang o higit pa upang makapag-registrar.')),
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
                title: const Text('Matagumpay ang Pagpaparehistro'),
                content: const Text(
                  'Isinagawa na ang email ng beripikasyon. Iri-redirect ka sa home screen sa lalong madaling panahon.',
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
              title: const Text('Nakapag-login!'),
              content: const Text('Matagumpay kang nakapag-login. Iri-redirect ka sa pangunahing menu...'),
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
          SnackBar(content: Text('Mali ang mga kredensyal sa pag-login. Paki-try ulit.')),
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
          title: const Text('Nalimutan ang Password?'),
          content: const Text(
              'aw ay ire-redirect sa pahina ng pag-reset ng password. Nais mo bang magpatuloy?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Icancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _launchForgotPasswordUrl(); // Redirect to the external URL
              },
              child: const Text('Ituloy'),
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
        title: Text(isLogin ? 'Mag-Login' : 'Mag-Sign Up'),
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
                  decoration: _inputDecoration('Unang pangalan'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Paki-enter ang iyong unang pangalan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Apelyido'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Paki-enter ang iyong apelyido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _middleInitialController,
                  decoration: InputDecoration(
                    labelText: 'Panggitnang Inisyal',
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
                      return 'Paki-enter ang iyong panggitnang inisyals';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cellNumberController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Cellphone Number',
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
                      return 'Paki-enter ang isang wastong numero ng cellphone (Philippines number lamang)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateOfBirthController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration('Petsa ng Kapanganakan', suffixIcon: const Icon(Icons.calendar_today)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Paki-enter ang iyong petsa ng kapanganakan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  decoration: _inputDecoration('Kasarian'),
                  items: ['Lalaki', 'Babae'].map((String value) {
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
                    return 'Paki-enter ang isang wastong email';
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
                      return 'Paki-enter ang iyong password';
                    }
                  } else {
                    if (value == null || !RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$').hasMatch(value)) {
                      return 'Ang password ay dapat na may hindi bababa sa 8 na karakter, maglaman ng isang malaking titik, isang numero, at isang espesyal na karakter';
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
                    'Kumpirmahin ang Password',
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
                      return 'Hindi magkatugma ang mga password';
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
                                title: const Text('Tinatanggap ko ang Mga Tuntunin at Kundisyon'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Kinokolekta namin ang iyong personal na impormasyon para lamang sa layunin ng pagrerehistro. Sa pagpapatuloy, sumasang-ayon ka sa aming mga tuntunin ng privacy ng data.'),
                                      const SizedBox(height: 10),
                                      const Text('1. Pagkolekta ng Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Kinokolekta namin ang iyong pangalan, email, kaarawan, at impormasyon sa kontak.'),
                                      const SizedBox(height: 10),
                                      const Text('2. Paggamit ng Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Ang iyong data ay ginagamit para sa paggawa ng account, seguridad, at mga update sa serbisyo.'),
                                      const SizedBox(height: 10),
                                      const Text('3. Proteksyon ng Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Kami ay gumagamit ng encryption at mga hakbang sa seguridad upang maprotektahan ang iyong data.'),
                                      const SizedBox(height: 10),
                                      const Text('4. Pag-iingat at Karapatan:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Maaari mong baguhin o tanggalin ang iyong data, at mag-request ng pagtanggal ng data kapag hindi na ito kailangan.')
                                      ,
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Iclose'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text(
                          'Tinatanggap ko ang Mga Tuntunin at Kondisyon',
                          style: TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Mag-Sign Up'),
                ),
              ],
              if (isLogin) ...[
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Mag-Login'),
                ),
              ],
              TextButton(
                onPressed: toggleFormType,
                child: Text(isLogin ? "Wala pang account? Mag-sign Up" : 'May account na? Mag-login'),
              ),
              if (isLogin)
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Nalimutan ang password?'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
