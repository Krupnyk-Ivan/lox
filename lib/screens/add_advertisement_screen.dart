import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class AddAdvertisementScreen extends StatefulWidget {
  const AddAdvertisementScreen({super.key});

  @override
  State<AddAdvertisementScreen> createState() => _AddAdvertisementScreenState();
}

Future<File> _createFakeImageFile() async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/fake.jpg');
  // Запишемо просто білий піксель (мінімальна jpg-заглушка)
  final minimalJpegBytes = [
    0xFF, 0xD8, // SOI
    0xFF, 0xD9, // EOI
  ];
  return await file.writeAsBytes(minimalJpegBytes);
}

class _AddAdvertisementScreenState extends State<AddAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;

  final List<String> _categories = [
    'Electronics',
    'Clothes',
    'Transport',
    'Real Estate',
  ];
  Future<void> _submitAdvertisement() async {
    if (_formKey.currentState!.validate()) {
      final uri = Uri.parse(
        'http://10.0.2.2:7210/api/Advertisements/create-advertisement',
      );
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['categoryId'] = '1'; // TODO: dynamic
      request.fields['regionId'] = '1'; // TODO: dynamic
      request.fields['sellerId'] = '1'; // TODO: залогінений користувач
      // Add other fields as needed (e.g., categoryId, regionId, sellerId)

      final imageFile =
          await pickImage(); // This is a method that lets the user pick an image
      // Optional: Add the base64 string if an image is selected

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes(); // Read the image bytes
        final base64Image = base64Encode(
          bytes,
        ); // Encode image to Base64 string
        request.fields['imageBase64'] =
            base64Image; // Add Base64 image to request fields
        request.fields['image_data'] =
            base64Image; // You may need this depending on your server-side setup
      }
      if (imageFile != null) {
        // Correct way to add an image file to a multipart request
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // This name MUST match the parameter name in the C# controller (IFormFile? image)
            imageFile.path,
            // Optional: contentType specifies the MIME type of the file
            // contentType: MediaType('image', 'jpeg'), // Add this line if you have the MediaType package
          ),
        );
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Advertisement added')));
          Navigator.pop(context);
        } else {
          // Parse the error message from the backend response if available
          String errorMessage = 'Server error';
          try {
            final errorJson = jsonDecode(response.body);
            if (errorJson != null && errorJson['message'] != null) {
              errorMessage = errorJson['message'];
            } else {
              errorMessage = 'Server error: ${response.statusCode}';
            }
          } catch (e) {
            errorMessage =
                'Server error: ${response.statusCode} - ${response.body}';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Advertisement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter description'
                            : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value == null || value.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Select category' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitAdvertisement,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
