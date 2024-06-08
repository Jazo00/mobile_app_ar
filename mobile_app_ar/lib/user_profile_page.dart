// File: user_profile_page.dart

import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('User ID: $userId'),
    );
  }
}
