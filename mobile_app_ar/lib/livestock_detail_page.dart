// File: livestock_detail_page.dart

import 'package:flutter/material.dart';

class LivestockDetailPage extends StatelessWidget {
  final Map<String, dynamic> livestock;

  LivestockDetailPage({required this.livestock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable automatic back button
        title: Text(livestock['livestock_name'] ?? 'Livestock Detail'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
          children: [
            // Display the larger image centered above the information
            Image.asset(
              livestock['image_path'] ?? 'lib/assets/chicken.png',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              livestock['livestock_name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Breed: ${livestock['livestock_breed'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              livestock['livestock_information'] ?? 'No information available',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
