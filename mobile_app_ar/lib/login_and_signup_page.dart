import 'package:flutter/material.dart';

class LoginAndSignupPage extends StatefulWidget {
  @override
  _LoginAndSignupPageState createState() => _LoginAndSignupPageState();
}

class _LoginAndSignupPageState extends State<LoginAndSignupPage> {
  bool isLogin = true;

  void toggleFormType() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLogin ? 'Login' : 'Sign Up',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Handle login or signup logic
                },
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
    );
  }
}
