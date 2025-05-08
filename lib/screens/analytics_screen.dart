// Flutter: screens/analytics_screen.dart

import 'package:flutter/material.dart';
import '../services/advertisement_service.dart';
import '../models/analytics_dtos.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Futures to hold the analytics data
  late Future<List<CategoryCountDto>> _futureCategoryCounts;
  late Future<List<RegionCountDto>> _futureRegionCounts;

  // Add a future for total count if you want to display it
  // late Future<int> _futureTotalCount;

  @override
  void initState() {
    super.initState();
    // Fetch the analytics data when the screen initializes
    _futureCategoryCounts =
        AdvertisementService().fetchAdvertisementsCountByCategory();
    _futureRegionCounts =
        AdvertisementService().fetchAdvertisementsCountByRegion();
    // _futureTotalCount = AdvertisementService().GetTotalAdvertisementsCount(); // Uncomment if you implemented this service method
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика популярності'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Use SingleChildScrollView for scrollable content
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align content to the start
          children: [
            // === Section: Most Popular Categories ===
            Text(
              'Найпопулярніші категорії (за кількістю оголошень)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // FutureBuilder for Category Counts
            FutureBuilder<List<CategoryCountDto>>(
              future: _futureCategoryCounts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Помилка завантаження категорій: ${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Статистика по категоріях відсутня.'),
                  );
                }

                final sortedCategories =
                    snapshot.data!..sort((a, b) => b.count.compareTo(a.count));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      sortedCategories.take(10).map((category) {
                        // Display top 10 categories
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                // Expanded to prevent overflow for long names
                                child: Text(
                                  category.categoryName ?? 'Невідома категорія',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${category.count} оголошень',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),

            const SizedBox(height: 32), // Spacing between sections
            // === Section: Most Popular Regions ===
            Text(
              'Найпопулярніші регіони (за кількістю оголошень)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // FutureBuilder for Region Counts
            FutureBuilder<List<RegionCountDto>>(
              future: _futureRegionCounts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Помилка завантаження регіонів: ${snapshot.error}',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Статистика по регіонах відсутня.'),
                  );
                }

                // Sort regions by count in descending order
                final sortedRegions =
                    snapshot.data!..sort((a, b) => b.count.compareTo(a.count));

                // Display the sorted list (e.g., top 10 or all)
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      sortedRegions.take(10).map((region) {
                        // Display top 10 regions
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  region.regionName ?? 'Невідомий регіон',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${region.count} оголошень',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),

            // Optional: Add section for Total Count
            // if (_futureTotalCount != null) ...
          ],
        ),
      ),
    );
  }
}
