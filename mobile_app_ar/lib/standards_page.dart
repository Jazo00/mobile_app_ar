// File: standards_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StandardsPage extends StatefulWidget {
  final String livestockId;

  StandardsPage({required this.livestockId});

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
        .eq('ls_id_fk', widget.livestockId)  // Filter by livestock ID
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

  String _getStringValue(dynamic value) {
    return value ?? 'N/A';
  }

  int _getIntValue(dynamic value) {
    return value ?? 0;
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
                              Text('Feed: ${_getStringValue(item['ls_feed'])}'),
                              const SizedBox(height: 8),
                              Text('Meds: ${_getStringValue(item['ls_meds'])}'),
                              const SizedBox(height: 8),
                              Text('Age (days): ${_getIntValue(item['ls_age_days'])}'),
                              const SizedBox(height: 8),
                              Text('Age (weeks): ${_getIntValue(item['ls_age_weeks'])}'),
                              const SizedBox(height: 8),
                              Text('Age (months): ${_getIntValue(item['ls_age_months'])}'),
                              const SizedBox(height: 8),
                              Text('Age (years): ${_getIntValue(item['ls_age_years'])}'),
                              const SizedBox(height: 8),
                              Text('Ideal Living Conditions: ${_getStringValue(item['ideal_living_conditions'])}'),
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
