// File: standards_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StandardsPage extends StatefulWidget {
  @override
  _StandardsPageState createState() => _StandardsPageState();
}

class _StandardsPageState extends State<StandardsPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _livestockHealthData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLivestockHealthData();
  }

  Future<void> _fetchLivestockHealthData() async {
    final response = await _supabaseClient
        .from('livestock_health')
        .select()
        .execute();

    if (response.error == null) {
      setState(() {
        _livestockHealthData = List<Map<String, dynamic>>.from(response.data);
        _isLoading = false;
      });
    } else {
      // Handle error
      print('Error fetching data: ${response.error!.message}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getLivestockType(dynamic livestockType) {
    if (livestockType == 1) {
      return 'Chicken';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Standards for a Healthy Life Cycle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _livestockHealthData.isEmpty
                ? Center(child: Text('No data available'))
                : ListView.builder(
                    itemCount: _livestockHealthData.length,
                    itemBuilder: (context, index) {
                      final item = _livestockHealthData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Feed: ${item['ls_feed'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Meds: ${item['ls_meds'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Age (days): ${item['ls_age_days'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Age (weeks): ${item['ls_age_weeks'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Age (months): ${item['ls_age_months'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Age (years): ${item['ls_age_years'] ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              Text('Livestock Type: ${_getLivestockType(item['ls_livestock_type'])}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
