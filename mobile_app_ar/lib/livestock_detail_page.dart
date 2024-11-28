// File: livestock_detail_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'standards_page.dart';  // Import the new Standards page

class LivestockDetailPage extends StatelessWidget {
  final Map<String, dynamic> livestock;

  const LivestockDetailPage({super.key, required this.livestock});

  @override
  Widget build(BuildContext context) {
    print('Livestock map: $livestock'); // Debugging log for entire map

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable automatic back button
        title: Text(livestock['livestock_name'] ?? 'Livestock Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              // Display the larger image centered above the information
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2.0),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    livestock['livestock_image'] ?? 'https://via.placeholder.com/200', // Use the livestock_image field
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                livestock['livestock_name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Breed: ${livestock['livestock_breed'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                livestock['livestock_information'] ?? 'Walang pang impormasyon',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // Updated "View in AR" Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  final Uri unityAppUri = Uri.parse('agrilenzscheme://agrilenz');  // Custom URI for Unity app
                  if (await canLaunchUrl(unityAppUri)) {
                    await launchUrl(unityAppUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hindi mailunsad ang AR view')),
                    );
                  }
                },
                child: const Text(
                  'Tingnan sa AR',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  final livestockId = livestock['livestock_id'];
                  print('Livestock ID: $livestockId'); // Debugging log for livestock_id
                  if (livestockId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StandardsPage(
                          livestockId: livestockId, // Pass livestock ID
                        ),
                      ),
                    );
                  } else {
                    // Handle case where livestockId is null
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: Livestock ID is null')),
                    );
                  }
                },
                child: const Text(
                  'Pamantayan para sa Isang Malusog na Siklo ng Buhay ng Livestock',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
