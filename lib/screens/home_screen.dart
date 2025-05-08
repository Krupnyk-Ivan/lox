import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import 'dart:convert';
import '../screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/advertisement_detail_screen.dart';
import '../models/category.dart';
import '../models/region.dart';
import '../services/Favorites_Service.dart';
import '../screens/my_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Advertisement>> futureAds;
  String _searchQuery = '';
  int? _selectedCategoryId;
  int? _selectedRegionId;
  List<Category> _categories = [];
  List<Region> _regions = [];
  List<Advertisement> recommendedAds = [];

  @override
  void initState() {
    super.initState();
    futureAds = AdvertisementService().fetchAdvertisements();
    _loadFilters();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      final userProvider = Provider.of<UserProvider>(context);
      final user = userProvider.user;
      final buyerId = user!.id; // Замінити на реальний ID покупця
      recommendedAds = await AdvertisementService().fetchRecommendations(
        buyerId,
      );
      setState(() {});
    } catch (e) {
      print("Помилка при завантаженні рекомендацій: $e");
    }
  }

  void _loadFilters() async {
    final categories = await AdvertisementService().fetchCategories();
    final regions = await AdvertisementService().fetchRegions();

    setState(() {
      _categories = categories;
      _regions = regions;
    });
  }

  void _refreshAdvertisements() async {
    final ads = await AdvertisementService().fetchAdvertisements();
    final favIds = await FavoritesService().loadFavorites();

    setState(() {
      futureAds = Future.value(
        ads.map((ad) {
          ad.isFavorite = favIds.contains(ad.id);
          return ad;
        }).toList(),
      );
    });
  }

  Set<int> _favoriteAdIds = {};

  bool isFavorite(int adId) {
    return _favoriteAdIds.contains(adId);
  }

  void toggleFavorite(int adId) {
    setState(() {
      if (_favoriteAdIds.contains(adId)) {
        _favoriteAdIds.remove(adId);
      } else {
        _favoriteAdIds.add(adId);
      }
    });
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
              _refreshAdvertisements();
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Категорія'),
                  items:
                      _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedRegionId,
                  decoration: const InputDecoration(labelText: 'Регіон'),
                  items:
                      _regions
                          .map(
                            (reg) => DropdownMenuItem(
                              value: reg.id,
                              child: Text(reg.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegionId = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        if (recommendedAds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Рекомендовані для вас',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180, // Висота картки
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedAds.length,
                    itemBuilder: (context, index) {
                      final ad = recommendedAds[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AdvertisementDetailScreen(
                                    advertisementId: ad.id!,
                                  ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ad.imageBase64 != null
                                    ? Image.memory(
                                      base64Decode(ad.imageBase64!),
                                      width: 150,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                    : const Icon(
                                      Icons.image_not_supported,
                                      size: 100,
                                    ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    ad.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    '${ad.price.toStringAsFixed(2)} UAH',
                                    style: const TextStyle(color: Colors.green),
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
              ],
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
                  snapshot.data!.where((ad) {
                    final matchesTitle = ad.title.toLowerCase().contains(
                      _searchQuery,
                    );
                    final matchesCategory =
                        _selectedCategoryId == null ||
                        ad.categoryId == _selectedCategoryId;
                    final matchesRegion =
                        _selectedRegionId == null ||
                        ad.regionId == _selectedRegionId;
                    return matchesTitle && matchesCategory && matchesRegion;
                  }).toList();

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
                              trailing: IconButton(
                                icon: Icon(
                                  isFavorite(ad.id!)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  toggleFavorite(ad.id!);
                                },
                              ),
                              onTap: () {
                                _refreshAdvertisements();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AdvertisementDetailScreen(
                                          advertisementId: ad.id!,
                                        ),
                                  ),
                                );
                                _refreshAdvertisements();
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

  Widget _buildFavorites() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    return FutureBuilder<List<Advertisement>>(
      future: futureAds,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Немає оголошень.'));
        }

        // Правильна перевірка ролі користувача
        final filteredAds =
            user?.userType == 'Seller'
                ? snapshot.data!.where((ad) => ad.sellerId == user?.id).toList()
                : snapshot.data!
                    .where((ad) => _favoriteAdIds.contains(ad.id))
                    .toList();

        if (filteredAds.isEmpty) {
          return Center(
            child: Text(
              user?.userType == 'Seller'
                  ? 'У вас немає створених оголошень.'
                  : 'Немає вибраних оголошень.',
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredAds.length,
          itemBuilder: (context, index) {
            final ad = filteredAds[index];

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
                      return const Center(child: CircularProgressIndicator());
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
                        trailing:
                            user?.userType == 'Seller'
                                ? null
                                : IconButton(
                                  icon: Icon(
                                    isFavorite(ad.id!)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    toggleFavorite(ad.id!);
                                  },
                                ),
                        onTap: () {
                          _refreshAdvertisements();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AdvertisementDetailScreen(
                                    advertisementId: ad.id!,
                                  ),
                            ),
                          );
                          _refreshAdvertisements();
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

  Widget _buildOrders() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user == null) {
      // Повертає логін-екран замість профілю
      return const LoginScreen();
    }
    return MyOrdersScreen();
  }

  List<Widget> _buildScreens() {
    return [_buildAdList(), _buildFavorites(), _buildOrders(), _buildProfile()];
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
            _refreshAdvertisements();
            loadRecommendations();

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
            label: 'Замовлення',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профіль'),
        ],
      ),
    );
  }
}
