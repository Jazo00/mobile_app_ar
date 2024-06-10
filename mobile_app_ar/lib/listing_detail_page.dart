// File: listing_detail_page.dart

import 'package:flutter/material.dart';

class ListingDetailPage extends StatelessWidget {
  final Map<String, dynamic> listing;

  ListingDetailPage({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(listing['listing_title'] ?? 'Listing Detail'),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            listing['listing_image'] != null
                ? Image.network(
                    listing['listing_image'],
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error);
                    },
                  )
                : Image.asset(
                    'lib/assets/chicken.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
            const SizedBox(height: 16),
            Text(
              listing['listing_title'] ?? 'No Title',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${listing['listing_price']?.toString() ?? 'No Price'}',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              listing['listing_description'] ?? 'No description available',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Seller: ${listing['seller_name'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // This button does nothing for now
              },
              child: Text('Buy Now'),
            ),
          ],
        ),
      ),
    );
  }
}
