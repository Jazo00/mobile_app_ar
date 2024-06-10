import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'listing_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final SupabaseClient _supabaseClient = SupabaseClient(
    'https://fbofelxkabyqngzbtuuo.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZib2ZlbHhrYWJ5cW5nemJ0dXVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc3NjE0OTgsImV4cCI6MjAzMzMzNzQ5OH0.rexRkyI9f2-wOrqLkTx-tRU1ObpE_CKDOIWtW2hPRk8',
  );
  List<Map<String, dynamic>> _listingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllListings();
  }

  Future<void> _fetchAllListings() async {
    try {
      final response = await _supabaseClient
          .from('listing')
          .select('listing_id, listing_title, listing_description, listing_price, created_at, user_id')
          .execute();

      print('Listings response: ${response.data}');
      if (response.error == null && response.data != null) {
        List<Map<String, dynamic>> listings = List<Map<String, dynamic>>.from(response.data);
        print('Parsed listings: $listings');

        if (listings.isEmpty) {
          setState(() {
            _error = 'No listings found';
            _isLoading = false;
          });
          return;
        }

        final userIds = listings.map((listing) => listing['user_id']).toList();
        print('User IDs: $userIds');
        if (userIds.isEmpty) {
          setState(() {
            _error = 'No user IDs found';
            _isLoading = false;
          });
          return;
        }

        final userProfilesResponse = await _supabaseClient
            .from('profiles')
            .select('userId, first_name, last_name')
            .in_('userId', userIds)
            .execute();

        print('User profiles response: ${userProfilesResponse.data}');
        if (userProfilesResponse.error == null && userProfilesResponse.data != null) {
          List<Map<String, dynamic>> userProfiles = List<Map<String, dynamic>>.from(userProfilesResponse.data);
          print('Parsed user profiles: $userProfiles');

          for (var listing in listings) {
            final userProfile = userProfiles.firstWhere((profile) => profile['userId'] == listing['user_id'], orElse: () => {});
            listing['seller_name'] = '${userProfile['first_name'] ?? 'Unknown'} ${userProfile['last_name'] ?? ''}'.trim();
          }

          setState(() {
            _listingList = listings;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = userProfilesResponse.error?.message ?? 'Failed to load user profiles';
            _isLoading = false;
          });
        }
      } else {
        print('Error in listings response: ${response.error}');
        setState(() {
          _error = response.error?.message ?? 'No data found';
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Exception: $error');
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(Map<String, dynamic> listing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailPage(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(2.0), 
        child: AppBar(
          automaticallyImplyLeading: false,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ListView.builder(
                    itemCount: _listingList.length,
                    itemBuilder: (context, index) {
                      final listing = _listingList[index];
                      return GestureDetector(
                        onTap: () => _navigateToDetail(listing),
                        child: Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                listing['listing_image'] != null
                                    ? Image.network(
                                        listing['listing_image'],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.error);
                                        },
                                      )
                                    : Image.asset(
                                        'lib/assets/chicken.png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing['listing_title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\₱${listing['listing_price']?.toString() ?? 'No Price'}',
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
                                      const SizedBox(height: 8),
                                      Text(
                                        'Posted on: ${listing['created_at'] ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
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
