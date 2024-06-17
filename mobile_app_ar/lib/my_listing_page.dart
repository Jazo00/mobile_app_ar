import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'listing_detail_page.dart';
import 'update_listing_page.dart'; // Import the new page

class MyListingPage extends StatefulWidget {
  @override
  _MyListingPageState createState() => _MyListingPageState();
}

class _MyListingPageState extends State<MyListingPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _listingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final authUserEmail = _supabaseClient.auth.currentUser?.email;
      if (authUserEmail == null) throw Exception('User not authenticated');

      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('email', authUserEmail)
          .single()
          .execute();

      if (response.error != null || response.data == null) {
        throw Exception(response.error?.message ?? 'Failed to fetch user data');
      }

      final userId = response.data['userId'];
      await _fetchMyListings(userId);
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMyListings(String userId) async {
    try {
      final response = await _supabaseClient
          .from('listing')
          .select('listing_id, listing_title, listing_description, listing_price, listing_image, created_at, user_id')
          .eq('user_id', userId)
          .execute();

      if (response.error != null || response.data == null) {
        throw Exception(response.error?.message ?? 'No data found');
      }

      List<Map<String, dynamic>> listings = List<Map<String, dynamic>>.from(response.data);
      if (listings.isEmpty) {
        throw Exception('No listings found');
      }

      final userIds = listings.map((listing) => listing['user_id']).toList();
      if (userIds.isEmpty) {
        throw Exception('No user IDs found');
      }

      final userProfilesResponse = await _supabaseClient
          .from('profiles')
          .select('userId, first_name, last_name')
          .in_('userId', userIds)
          .execute();

      if (userProfilesResponse.error != null || userProfilesResponse.data == null) {
        throw Exception(userProfilesResponse.error?.message ?? 'Failed to load user profiles');
      }

      List<Map<String, dynamic>> userProfiles = List<Map<String, dynamic>>.from(userProfilesResponse.data);
      for (var listing in listings) {
        final userProfile = userProfiles.firstWhere(
            (profile) => profile['userId'] == listing['user_id'],
            orElse: () => {});
        listing['seller_name'] =
            '${userProfile['first_name'] ?? 'Unknown'} ${userProfile['last_name'] ?? ''}'.trim();
      }

      setState(() {
        _listingList = listings;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteListing(String listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteListing(listingId);
    }
  }

  Future<void> _deleteListing(String listingId) async {
    try {
      final response = await _supabaseClient
          .from('listing')
          .delete()
          .eq('listing_id', listingId)
          .execute();

      if (response.error != null) {
        throw Exception(response.error?.message ?? 'Failed to delete listing');
      }

      setState(() {
        _listingList.removeWhere((listing) => listing['listing_id'] == listingId);
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _updateListing(String listingId) async {
    final listing = _listingList.firstWhere((listing) => listing['listing_id'] == listingId);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateListingPage(listing: listing),
      ),
    );

    if (result == true) {
      _fetchUserData();
    }
  }

  Future<void> _markAsSold(String listingId) async {
    // Implement your mark as sold logic here
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('My Listings'),
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
                      final imageUrl = listing['listing_image'] != null && !listing['listing_image'].startsWith('http')
                          ? 'https://example.com${listing['listing_image']}'
                          : listing['listing_image'];

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  width: 64.0,
                                  height: 64.0,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image, size: 64.0),
                          title: Text(listing['listing_title'] ?? ''),
                          subtitle: Text('Price: \$${listing['listing_price'] ?? 0}\nDescription: ${listing['listing_description'] ?? ''}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _confirmDeleteListing(listing['listing_id']);
                              } else if (value == 'update') {
                                _updateListing(listing['listing_id']);
                              } else if (value == 'markAsSold') {
                                _markAsSold(listing['listing_id']);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'update',
                                  child: Text('Update'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'markAsSold',
                                  child: Text('Mark as Sold'),
                                ),
                              ];
                            },
                          ),
                          onTap: () => _navigateToDetail(listing),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
