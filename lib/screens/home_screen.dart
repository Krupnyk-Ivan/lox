import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import 'dart:convert';
import '../screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Advertisement>> futureAds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    futureAds = AdvertisementService().fetchAdvertisements();
  }

  Widget _buildAdList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Пошук оголошень...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Advertisement>>(
            future: futureAds,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No ads found.'));
              }

              final ads =
                  snapshot.data!
                      .where(
                        (ad) => ad.title.toLowerCase().contains(_searchQuery),
                      )
                      .toList();

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
                      }

                      final category = categorySnapshot.data ?? '';

                      return FutureBuilder<String>(
                        future: AdvertisementService().fetchRegionNameById(
                          ad.regionId!,
                        ),
                        builder: (context, regionSnapshot) {
                          if (regionSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (regionSnapshot.hasError) {
                            return Center(
                              child: Text('Error: ${regionSnapshot.error}'),
                            );
                          }

                          final region = regionSnapshot.data ?? '';

                          return Card(
                            child: ListTile(
                              leading:
                                  ad.imageBase64 != null
                                      ? Image.memory(
                                        base64Decode(ad.imageBase64!),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                              title: Text(ad.title),
                              subtitle: Text(
                                '$region - $category\n${ad.price.toStringAsFixed(2)} UAH',
                              ),
                              isThreeLine: true,
                              onTap: () {
                                // Navigate to detailed ad screen
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
          ),
        ),
      ],
    );
  }

  Widget _buildAddAdForm() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      // Повертає логін-екран замість профілю
      return const LoginScreen();
    }
    return const Center(child: Text("Add Advertisement Screen"));
  }

  Widget _buildProfile() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      // Повертає логін-екран замість профілю
      return const LoginScreen();
    }

    return ProfileScreen(
      name: user.name,
      email: user.email,
      usertype: user.userType,
    );
  }

  List<Widget> _buildScreens() {
    return [
      _buildAdList(),
      _buildAddAdForm(),
      const Center(child: Text("Повідомлення")),
      _buildProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LOX '), centerTitle: true),
      body: _buildScreens()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green[100],
        selectedItemColor: Colors.green[900],
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Головна'),
          BottomNavigationBarItem(
            icon: Icon(Icons.heat_pump_rounded),
            label: 'Вибране',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Повідомлення',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профіль'),
        ],
      ),
    );
  }
}
