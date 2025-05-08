// Flutter: screens/all_advertisements_screen.dart

import 'package:flutter/material.dart';
import '../models/advertisement.dart'; // Import Advertisement model
import '../services/advertisement_service.dart'; // Or your service with fetchAllAdvertisements
import 'package:intl/intl.dart'; // For date formatting
// === NEW IMPORTS for Export ===
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

// ===========================
// import 'package:provider/provider.dart'; // Needed if checking user role

class AllAdvertisementsScreen extends StatefulWidget {
  const AllAdvertisementsScreen({super.key});

  @override
  State<AllAdvertisementsScreen> createState() =>
      _AllAdvertisementsScreenState();
}

class _AllAdvertisementsScreenState extends State<AllAdvertisementsScreen> {
  late Future<List<Advertisement>> _futureAllAdvertisements;
  // Keep the fetched data to export without refetching
  List<Advertisement>? _loadedAdvertisements; // Store the loaded data

  @override
  void initState() {
    super.initState();

    _futureAllAdvertisements = AdvertisementService().fetchAdvertisements();
    _futureAllAdvertisements
        .then((ads) {
          _loadedAdvertisements = ads;
        })
        .catchError((error) {
          print('Error fetching all advertisements in initState: $error');
          // FutureBuilder will show the error
        });
  }

  // === NEW METHOD: Export All Advertisements to CSV ===
  Future<void> _exportAllAdvertisements() async {
    // Check if advertisements are loaded
    if (_loadedAdvertisements == null || _loadedAdvertisements!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Немає даних оголошень для експорту.')),
      );
      return;
    }

    // TODO: Handle Storage Permissions if saving to external storage (like Downloads)

    // Prepare CSV data
    List<List<dynamic>> csvData = [];

    // Add header row - select relevant fields from your Advertisement model
    csvData.add([
      'ID Оголошення',
      'Заголовок',
      'Опис',
      'Ціна',
      'ID Продавця',
      'ID Категорії',
      'Назва Категорії', // Assuming categoryName is available in model or can be looked up
      'ID Регіону',
      'Назва Регіону', // Assuming regionName is available in model or can be looked up
      'Дата Створення',
      // Exclude large/binary fields like ImageBase64
    ]);

    // Add advertisement data rows
    for (var ad in _loadedAdvertisements!) {
      // Use properties from your Advertisement model
      final formattedDate =
          ad.createdDate != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(ad.createdDate!)
              : '';
      // Assuming categoryName and regionName are available directly in the Advertisement model
      // or you have a way to map category/region IDs to names if only IDs are available here.
      // If only IDs are available, you might need the _filterCategories and _filterRegions lists from HomeScreen
      // or fetch them here (less efficient) or modify the backend endpoint to include names.

      csvData.add([
        ad.id,
        ad.title,
        ad.description,
        ad.price.toStringAsFixed(2), // Format price
        ad.sellerId,
        ad.categoryId,
        ad.regionId,
        formattedDate,
        // Exclude ad.imageBase64
      ]);
    }

    // Convert data to CSV string
    String csvString = const ListToCsvConverter().convert(csvData);

    // Get application documents directory path
    Directory? directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (e) {
      print('Error getting documents directory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не вдалося отримати шлях до папки: ${e.toString()}'),
        ),
      );
      return;
    }

    // Create a file name
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final fileName = 'all_advertisements_${formatter.format(now)}.csv';
    final filePath = '${directory!.path}/$fileName';

    // Write to file
    File file = File(filePath);
    try {
      await file.writeAsString(csvString);
      print('CSV file saved to: $filePath');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Усі оголошення збережено як $fileName у ${directory.path}',
          ),
          // Optional: Add an action to open or share the file
        ),
      );
    } catch (e) {
      print('Error writing CSV file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка збереження файлу: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Усі оголошення (Адмін)',
        ), // Title indicating it's for all ads
        centerTitle: true,
        // === NEW: Add Export Button ===
        actions: [
          IconButton(
            icon: const Icon(Icons.download), // Download icon
            tooltip: 'Експортувати всі оголошення в CSV', // Tooltip text
            onPressed: _exportAllAdvertisements, // Call the export method
          ),
        ],
        // ==========================
      ),
      body: FutureBuilder<List<Advertisement>>(
        future: _futureAllAdvertisements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            if (snapshot.error.toString().contains('Unauthorized') ||
                snapshot.error.toString().contains('Forbidden')) {
              return const Center(
                child: Text('У вас немає прав для перегляду всіх оголошень.'),
              );
            }
            return Center(
              child: Text('Помилка завантаження оголошень: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            _loadedAdvertisements = [];
            return const Center(child: Text('Оголошення відсутні в системі.'));
          }

          _loadedAdvertisements = snapshot.data!;

          final allAds = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: allAds.length,
            itemBuilder: (context, index) {
              final ad = allAds[index];
              // Assuming categoryName and regionName are available in the Advertisement model
              final formattedDate =
                  ad.createdDate != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(ad.createdDate!)
                      : 'N/A';

              return Card(
                child: ListTile(
                  // Display relevant ad details
                  leading:
                      ad.imageBase64 != null && ad.imageBase64!.isNotEmpty
                          ? Image.memory(
                            base64Decode(ad.imageBase64!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 60),
                          )
                          : const Icon(Icons.image_not_supported, size: 60),
                  title: Text(ad.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${ad.id}, Продавець ID: ${ad.sellerId}'),
                      Text('Ціна: ${ad.price.toStringAsFixed(2)} UAH'),
                      Text(
                        'Категорія: ${ad.categoryId ?? 'N/A'}, Регіон: ${ad.regionId ?? 'N/A'}',
                      ),
                      Text('Дата створення: $formattedDate'),
                      Text(
                        'Опис: ${ad.description}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ), // Truncate description for list view
                    ],
                  ),
                  isThreeLine:
                      true, // Might need more lines depending on how many subtitle Text widgets you use
                  // Optional: onTap to view ad details screen
                  // onTap: () { /* Navigate to Advertisement Detail Screen */ },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
