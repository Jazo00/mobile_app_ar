// File: livestock_info.dart

import 'package:flutter/material.dart';

class LivestockInfoPage extends StatelessWidget {
  final String livestockId;

  LivestockInfoPage({required this.livestockId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Livestock ID: $livestockId'),
    );
  }
}
