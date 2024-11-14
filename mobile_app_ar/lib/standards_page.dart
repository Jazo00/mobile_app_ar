import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StandardsPage extends StatefulWidget {
  final String livestockId;

  const StandardsPage({super.key, required this.livestockId});

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
        .eq('ls_id_fk', widget.livestockId) // Filter by livestock ID
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
        title: const Text('Pamantayan para sa Isang Malusog na Siklo ng Buhay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _livestockHealthData.isEmpty
                ? const Center(child: Text('No data available'))
                : ListView.builder(
                    itemCount: _livestockHealthData.length,
                    itemBuilder: (context, index) {
                      final item = _livestockHealthData[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIdealInfoRow(Icons.restaurant, 'Pagkain', _getStringValue(item['ls_feed'])),
                              const SizedBox(height: 8),
                              _buildIdealInfoRow(Icons.medical_services, 'Gamot', _getStringValue(item['ls_meds'])),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.cake, 'Edad (Araw)', _getIntValue(item['ls_age_days']).toString()),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.calendar_today, 'Edad (Linggo)', _getIntValue(item['ls_age_weeks']).toString()),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.date_range, 'Edad (Buwan)', _getIntValue(item['ls_age_months']).toString()),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.timelapse, 'Edad (Taon)', _getIntValue(item['ls_age_years']).toString()),
                              const SizedBox(height: 16), // Add some space before the ideal conditions
                              _buildIdealLivingConditions(item['ideal_living_conditions']),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildIdealInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align the icon and label to the top
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildIdealLivingConditions(String? conditions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ideal na Kondisyon ng Pamumuhay:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4), // Space between label and value
        Text(
          _getStringValue(conditions),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
