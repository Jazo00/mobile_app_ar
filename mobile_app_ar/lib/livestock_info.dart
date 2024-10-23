// File: livestock_info.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async'; // Import for StreamSubscription to handle connectivity changes
import 'livestock_detail_page.dart';

class LivestockInfoPage extends StatefulWidget {
  const LivestockInfoPage({super.key});

  @override
  _LivestockInfoPageState createState() => _LivestockInfoPageState();
}

class _LivestockInfoPageState extends State<LivestockInfoPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _livestockList = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetAndFetch();

    // Listen to connectivity changes and fetch data on reconnection
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        // If internet is lost while loading, show the error immediately
        setState(() {
          _error = 'No internet connection. Data will refresh when reconnected.';
          _isLoading = false;
          _livestockList.clear();  // Clear partial data if loading interrupted
        });
      } else if (_error != null) {
        // Automatically fetch data once the connection is restored
        _checkInternetAndFetch();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  Future<void> _checkInternetAndFetch() async {
    setState(() {
      _isLoading = true; // Show loading indicator
      _error = null;     // Clear error when starting a new fetch
    });

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _error = 'No internet connection. Data will refresh when reconnected.';
        _isLoading = false;
      });
    } else {
      await _fetchAllLivestock(); // Fetch data if connected
    }
  }

  Future<void> _fetchAllLivestock() async {
    try {
      final response = await _supabaseClient
          .from('livestock')
          .select('livestock_id, livestock_name, livestock_breed, livestock_information, livestock_image')
          .execute();

      if (response.error == null && response.data != null) {
        setState(() {
          _livestockList = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
          _error = null;  // Clear error after successful data load
        });
      } else {
        setState(() {
          _error = response.error?.message ?? 'Failed to load data.';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Error loading data: $error';
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(Map<String, dynamic> livestock) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black, // Changed error message text color to black
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _checkInternetAndFetch,  // Allow manual refresh
                  child: ListView.builder(
                    itemCount: _livestockList.length,
                    itemBuilder: (context, index) {
                      final livestock = _livestockList[index];
                      return GestureDetector(
                        onTap: () => _navigateToDetail(livestock),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    livestock['livestock_image'] ?? 'https://via.placeholder.com/100',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.network(
                                        'https://via.placeholder.com/100',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        livestock['livestock_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 24,
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
                                        livestock['livestock_information'] ?? 'No information available',
                                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                ),
    );
  }
}
