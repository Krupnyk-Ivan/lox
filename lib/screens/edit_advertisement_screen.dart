// screens/edit_advertisement_screen.dart (Integrating Image Picking)

import 'package:flutter/material.dart';
import '../models/advertisement.dart';
import '../services/advertisement_service.dart';
import '../models/category.dart';
import '../models/region.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import 'dart:convert'; // For base64Decode, base64Encode
import 'dart:io'; // For File
import 'package:image_picker/image_picker.dart'; // For ImagePicker, XFile

class EditAdvertisementScreen extends StatefulWidget {
  final int advertisementId;

  const EditAdvertisementScreen({required this.advertisementId, super.key});

  @override
  State<EditAdvertisementScreen> createState() =>
      _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState extends State<EditAdvertisementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  List<Category> _categories = [];
  List<Region> _regions = [];
  Category? _selectedCategory;
  Region? _selectedRegion;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFilterOptionsLoading = true; // Should also track filter loading state

  final _formKey = GlobalKey<FormState>();

  // Store the original advertisement details after fetching
  // We keep this to potentially access other original properties if needed,
  // but _currentImageBase64 and _newPickedImageBase64 manage image state.
  Advertisement? _originalAdvertisement;

  // Store the Base64 of the ORIGINAL image fetched from the backend
  String? _currentImageBase64;
  int? _sellerid;
  // === ДОДАНО: Змінна для зберігання Base64 НОВОГО обраного зображення ===
  String? _newPickedImageBase64;

  @override
  void initState() {
    super.initState();
    // Load initial data and filter options
    _loadAdvertisementData();
    // Assuming fetchFilterOptions was part of _loadAdvertisementData
    // _fetchFilterOptions(); // If filter options loading is separate
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // _currentImageBase64 and _newPickedImageBase64 are just strings, no dispose needed
    super.dispose();
  }

  // Метод для завантаження даних оголошення та опцій фільтрів
  Future<void> _loadAdvertisementData() async {
    setState(() {
      _isLoading = true;
      _isFilterOptionsLoading = true;
    }); // Start both loading indicators

    try {
      print(widget.advertisementId);
      final adFuture = AdvertisementService().fetchAdvertisement(
        widget.advertisementId,
      );
      final categoriesFuture = AdvertisementService().fetchCategories();
      final regionsFuture = AdvertisementService().fetchRegions();

      // Wait for ad data and filter options in parallel
      final results = await Future.wait([
        adFuture,
        categoriesFuture,
        regionsFuture,
      ]);

      final advertisement = results[0] as Advertisement;
      final categories = results[1] as List<Category>;
      final regions = results[2] as List<Region>;

      // Authorization check
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null || advertisement.sellerId != currentUser.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('У вас немає прав для редагування цього оголошення.'),
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Store original ad and its image base64
      _originalAdvertisement = advertisement;
      _currentImageBase64 =
          advertisement.imageBase64; // Store original image Base64
      _sellerid = advertisement.sellerId;
      // Populate controllers and selected dropdowns
      _titleController.text = advertisement.title;
      _descriptionController.text = advertisement.description;
      _priceController.text = advertisement.price.toString();

      _selectedCategory = categories.firstWhere(
        (cat) => cat.id == advertisement.categoryId,
        orElse: () => categories.first,
      );
      _selectedRegion = regions.firstWhere(
        (reg) => reg.id == advertisement.regionId,
        orElse: () => regions.first,
      );

      setState(() {
        _categories = categories;
        _regions = regions;
        _isLoading = false; // Ad data loading finished
        _isFilterOptionsLoading = false; // Filter options loading finished
      });
    } catch (e) {
      print('Помилка завантаження даних оголошення: $e');
      setState(() {
        _isLoading = false;
        _isFilterOptionsLoading = false;
      }); // Stop loading on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Помилка завантаження даних оголошення: ${e.toString()}',
          ),
        ),
      );
      // Optional: Pop on fatal loading error
      // Navigator.pop(context);
    }
  }

  // === ДОДАНО: Метод для вибору зображення з галереї та конвертації в Base64 ===
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Use pickImage for gallery
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(
          bytes,
        ); // Convert bytes to Base64 string

        setState(() {
          _newPickedImageBase64 = base64Image; // Store the new Base64 string
        });
        print('Image picked and converted to Base64.'); // Log success
      } catch (e) {
        print('Error picking or converting image: $e'); // Log error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка обробки зображення: ${e.toString()}'),
          ),
        );
      }
    } else {
      print('Image picking cancelled.'); // Log cancellation
      // Optional: Show a message that picking was cancelled
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Вибір зображення скасовано.')),
      // );
    }
  }

  // Метод для збереження змін
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      print(widget.advertisementId);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      try {
        // Determine which image Base64 to send: new picked or original
        // Use the new picked image if available, otherwise use the original image
        final imageBase64ToSend = _newPickedImageBase64 ?? _currentImageBase64;
        // Create the updated Advertisement object
        final imageFile = await pickImage(); // Or use the existing image if not

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = userProvider.user;
        await AdvertisementService().updateAdvertisement(
          id: widget.advertisementId,
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          sellerId: currentUser!.id,
          categoryId: _selectedCategory!.id,
          regionId: _selectedRegion!.id,
          imageFile: imageFile, // може бути null
        );
        // Успішне збереження
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Зміни успішно збережено!')),
        );
        Navigator.pop(context, true); // Повернутися назад з результатом
      } catch (e) {
        print('Помилка збереження змін: $e');
        String displayError = 'Помилка збереження змін: ${e.toString()}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(displayError)));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Determine which image to display: newly picked, original, or placeholder
    Widget currentImageWidget;
    if (_newPickedImageBase64 != null && _newPickedImageBase64!.isNotEmpty) {
      // Display the newly picked image
      currentImageWidget = Image.memory(
        base64Decode(_newPickedImageBase64!),
        height: 150,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 150, color: Colors.red),
      );
    } else if (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty) {
      // Display the original image if no new one is picked
      currentImageWidget = Image.memory(
        base64Decode(_currentImageBase64!),
        height: 150,
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 150, color: Colors.red),
      );
    } else {
      // Display a placeholder if no image exists
      currentImageWidget = const Icon(
        Icons.image_not_supported,
        size: 150,
        color: Colors.grey,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Редагувати оголошення')),
      body:
          _isLoading // Показуємо індикатор, якщо завантажуються дані оголошення АБО фільтри
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // ... Поля для заголовка, опису, ціни ...
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Заголовок',
                        ),
                        validator: (value) {
                          /* ... */
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Опис'),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        validator: (value) {
                          /* ... */
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Ціна'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          /* ... */
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ... Випадаючі списки (тепер перевіряємо тільки _isFilterOptionsLoading) ...
                      _isFilterOptionsLoading // Перевіряємо лише завантаження фільтрів
                          ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                          : DropdownButtonFormField<Category>(
                            decoration: const InputDecoration(
                              labelText: 'Категорія',
                            ),
                            value: _selectedCategory,
                            // Перевіряємо _categories.isEmpty, якщо завантаження завершено і список порожній
                            items:
                                _categories
                                    .map((category) {
                                      return DropdownMenuItem<Category>(
                                        value: category,
                                        child: Text(category.name),
                                      );
                                    })
                                    .toList()
                                    .followedBy([
                                      // Додаємо опцію "Не обрано" або подібне, якщо потрібно
                                      // DropdownMenuItem<Category>(value: null, child: Text('Оберіть категорію')),
                                    ])
                                    .toList(), // Convert back to list
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              /* ... */
                              return null;
                            },
                          ),
                      const SizedBox(height: 16),

                      _isFilterOptionsLoading // Перевіряємо лише завантаження фільтрів
                          ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                          : DropdownButtonFormField<Region>(
                            decoration: const InputDecoration(
                              labelText: 'Регіон',
                            ),
                            value: _selectedRegion,
                            // Перевіряємо _regions.isEmpty, якщо завантаження завершено і список порожній
                            items:
                                _regions
                                    .map((region) {
                                      return DropdownMenuItem<Region>(
                                        value: region,
                                        child: Text(region.name),
                                      );
                                    })
                                    .toList()
                                    .followedBy([
                                      // DropdownMenuItem<Region>(value: null, child: Text('Оберіть регіон')),
                                    ])
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRegion = value;
                              });
                            },
                            validator: (value) {
                              /* ... */
                              return null;
                            },
                          ),
                      const SizedBox(height: 16),

                      // === ДОДАНО: UI для відображення та вибору зображення ===
                      const Text(
                        'Зображення:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Відображаємо поточне або нове обране зображення
                      currentImageWidget,
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),

                      // Кнопка збереження
                      _isSaving
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _saveChanges,
                            child: const Text('Зберегти зміни'),
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
