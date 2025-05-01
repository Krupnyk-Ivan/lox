import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Advertisement>> futureAds;

  @override
  void initState() {
    super.initState();
    futureAds = AdvertisementService().fetchAdvertisements();
  }

  Widget _buildAdList() {
    return FutureBuilder<List<Advertisement>>(
      future: futureAds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No ads found.'));
        }

        final ads = snapshot.data!;
        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return FutureBuilder<String>(
              future: AdvertisementService().fetchCategoryNameById(
                ad.categoryId!,
              ),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (categorySnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${categorySnapshot.error}'),
                  );
                } else if (!categorySnapshot.hasData) {
                  return const Center(child: Text('No category data.'));
                }

                final category = categorySnapshot.data!;
                return FutureBuilder<String>(
                  future: AdvertisementService().fetchRegionNameById(
                    ad.regionId!,
                  ),
                  builder: (context, regionSnapshot) {
                    if (regionSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (regionSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${regionSnapshot.error}'),
                      );
                    } else if (!regionSnapshot.hasData) {
                      return const Center(child: Text('No region data.'));
                    }

                    final region = regionSnapshot.data!;
                    return Card(
                      child: ListTile(
                        title: Text(ad.title),
                        subtitle: Text(
                          '$region - $category\n${ad.price.toStringAsFixed(2)} UAH',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Navigate to detailed page
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAddAdForm() {
    return const Center(child: Text("Add Advertisement Screen"));
  }

  Widget _buildProfile() {
    return const Center(child: Text("Profile Screen"));
  }

  List<Widget> get _screens => [
    _buildAdList(),
    _buildAddAdForm(),
    _buildProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OLX Clone')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Ads'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
