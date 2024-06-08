// File: livestock_info.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LivestockInfoPage extends StatefulWidget {
  final String livestockId;

  LivestockInfoPage({required this.livestockId});

  @override
  _LivestockInfoPageState createState() => _LivestockInfoPageState();
}

class _LivestockInfoPageState extends State<LivestockInfoPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  Map<String, dynamic>? _livestockInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLivestockInfo();
  }

  Future<void> _fetchLivestockInfo() async {
    try {
      final response = await _supabaseClient
          .from('livestock')
          .select()
          .eq('livestock_id', widget.livestockId)
          .single()
          .execute();

      if (response.error == null) {
        setState(() {
          _livestockInfo = response.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error!.message;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Livestock Information'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _livestockInfo != null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _livestockInfo!['livestock_name'] ?? 'Unknown',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Breed: ${_livestockInfo!['livestock_breed'] ?? 'Unknown'}',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _livestockInfo!['livestock_information'] ?? 'No information available',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Center(child: Text('No information available')),
    );
  }
}
