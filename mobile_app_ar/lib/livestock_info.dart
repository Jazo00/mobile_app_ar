// File: livestock_info.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'livestock_detail_page.dart';

class LivestockInfoPage extends StatefulWidget {
  @override
  _LivestockInfoPageState createState() => _LivestockInfoPageState();
}

class _LivestockInfoPageState extends State<LivestockInfoPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _livestockList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllLivestock();
  }

  Future<void> _fetchAllLivestock() async {
    try {
      final response = await _supabaseClient
          .from('livestock')
          .select('livestock_id, livestock_name, livestock_breed, livestock_information')
          .execute();

      if (response.error == null && response.data != null) {
        setState(() {
          _livestockList = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error?.message ?? 'No data found';
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetail(Map<String, dynamic> livestock) {
    print('Navigating to detail with livestock: $livestock'); // Debugging log
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivestockDetailPage(livestock: livestock),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(17.0),
        child: AppBar(
          automaticallyImplyLeading: false,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  itemCount: _livestockList.length,
                  itemBuilder: (context, index) {
                    final livestock = _livestockList[index];
                    return GestureDetector(
                      onTap: () => _navigateToDetail(livestock),
                      child: Card(
                        margin: EdgeInsets.only(
                          left: 8.0,
                          right: 8.0,
                          top: index == 0 ? 0.0 : 4.0,
                          bottom: 4.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the larger image
                              Image.asset(
                                'lib/assets/chicken.png',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'lib/assets/chicken.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              // Display the livestock details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
