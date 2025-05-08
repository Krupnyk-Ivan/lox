import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/advertisement.dart';
import '../models/category.dart';
import '../models/feedback.dart';
import '../models/analytics_dtos.dart';
import '../models/region.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../models/order.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/region.dart';
import '../models/category.dart';
import 'package:provider/provider.dart';
import '../services/user_provider.dart';

class AdvertisementService {
  final String baseUrl =
      'http://10.0.2.2:7210/api'; // Update with your actual API URL

  // Fetch advertisements
  Future<List<Advertisement>> fetchAdvertisements() async {
    final response = await http.get(Uri.parse('$baseUrl/advertisements'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((ad) => Advertisement.fromJson(ad)).toList();
    } else {
      throw Exception('Failed to load advertisements');
    }
  }

  Future<List<CategoryCountDto>> fetchAdvertisementsCountByCategory() async {
    final uri = Uri.parse('$baseUrl/Analytics/advertisements/count/bycategory');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Use the CategoryCountDto.fromJson parser
        return data.map((item) => CategoryCountDto.fromJson(item)).toList();
      } else {
        // Handle errors similar to other fetch methods
        String errorMessage =
            'Failed to load category counts. Status code: ${response.statusCode}.';
        // ... (Robust error parsing logic) ...
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network errors
      print('Network error fetching category counts: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // === NEW METHOD: Fetch Advertisement Count by Region ===
  Future<List<RegionCountDto>> fetchAdvertisementsCountByRegion() async {
    final uri = Uri.parse('$baseUrl/Analytics/advertisements/count/byregion');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // Use the RegionCountDto.fromJson parser
        return data.map((item) => RegionCountDto.fromJson(item)).toList();
      } else {
        // Handle errors similar to other fetch methods
        String errorMessage =
            'Failed to load region counts. Status code: ${response.statusCode}.';
        // ... (Robust error parsing logic) ...
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network errors
      print('Network error fetching region counts: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<void> updateAdvertisement({
    required int id,
    required String title,
    required String description,
    required double price,
    required int sellerId,
    required int categoryId,
    required int regionId,
    File? imageFile, // може бути null
  }) async {
    final uri = Uri.parse('http://10.0.2.2:7210/api/Advertisements/$id/update');
    final request = http.MultipartRequest('PUT', uri);

    // Поля форми (мають відповідати іменам у DTO або [FromForm] параметрам)
    request.fields['id'] = id.toString();
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['price'] = price.toString().replaceAll('.', ',');
    request.fields['sellerId'] = sellerId.toString();
    request.fields['categoryId'] = categoryId.toString();
    request.fields['regionId'] = regionId.toString();
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.fields['ImageBase64'] = base64Encode(bytes);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Ім’я має відповідати параметру IFormFile? image у контролері
          imageFile.path,
          // contentType: MediaType('image', 'jpeg'), // якщо треба MIME
        ),
      );
    }

    // Відправка запиту
    final response = await request.send();

    if (response.statusCode == 204) {
      print('Оголошення оновлено');
    } else {
      final respStr = await response.stream.bytesToString();
      print('Помилка: ${response.statusCode}');
      print('Вміст відповіді: $respStr');
      throw Exception('Failed to update advertisement');
    }
  }

  Future<List<FeedbackModel>> fetchFeedbacks(int advertisementId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/Feedbacks/ad/$advertisementId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      // Тепер перетворюємо кожен елемент списку у FeedbackModel
      return jsonList
          .map((jsonMap) => FeedbackModel.fromJson(jsonMap))
          .toList();
    } else {
      throw Exception('Не вдалося завантажити відгуки');
    }
  }

  Future<List<Advertisement>> fetchRecommendations(int buyerId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/orders/recommendations/$buyerId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Advertisement.fromJson(json)).toList();
    } else {
      throw Exception('Не вдалося завантажити рекомендації');
    }
  }

  Future<void> addFeedback(
    int adId,
    int buyerId,
    String commentText,
    int rating,
  ) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:7210/api/Feedbacks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adId': adId,
        'buyerId': buyerId,
        'commentText': commentText,
        'rating': rating,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Не вдалося додати відгук');
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

  String _handleError(http.Response response) {
    try {
      final errorJson = jsonDecode(response.body);
      if (errorJson['errors'] != null) {
        return errorJson['errors'].values.expand((e) => e).join(', ');
      } else if (errorJson['message'] != null) {
        return errorJson['message'];
      }
    } catch (_) {
      // if response body is not JSON or has unexpected format
    }
    return 'Error ${response.statusCode}: ${response.body}';
  }

  // Fetch category name by ID
  Future<String> fetchCategoryNameById(int categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['name']; // Adjust based on the actual response format
    } else {
      throw Exception('Failed to load category');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/Categories'),
    );
    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> cancelOrder(int orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Orders/$orderId'), // URL to cancel the order
    );

    if (response.statusCode == 204) {
      // Successful cancellation
      print('Order $orderId canceled successfully');
    } else {
      // Error handling
      throw Exception('Failed to cancel order');
    }
  }

  // Confirm Order API
  Future<void> confirmOrder(int orderId) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:7210/status/$orderId'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'orderStatus': 'confirmed', // Example of sending order status update
      }),
    );

    if (response.statusCode == 204) {
      // Successful confirmation
      print('Order $orderId confirmed successfully');
    } else {
      // Error handling
      throw Exception('Failed to confirm order');
    }
  }

  Future<List<Order>> getOrders(int userId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/Orders/buyer/$userId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((order) => Order.fromJson(order)).toList();
    } else {
      throw Exception('Не вдалося завантажити замовлення');
    }
  }

  Future<List<Order>> getOrdersBySeller(int userId) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/Orders/seller/$userId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((order) => Order.fromJson(order)).toList();
    } else {
      throw Exception('Не вдалося завантажити замовлення');
    }
  }

  Future<Order> createOrder(Order orderData) async {
    // Accepts an Order object (or a DTO)
    final uri = Uri.parse('$baseUrl/Orders'); // Use the OrdersController route

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          orderData.toJson(),
        ), // Convert the Order object to JSON
      );

      if (response.statusCode == 201) {
        // Expect 201 Created
        // Parse the successful response body into an Order object
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return Order.fromJson(responseBody);
      } else {
        // Handle server errors (400, 404, 500 etc.)
        String errorMessage =
            'Failed to create order. Status code: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson != null && errorJson['message'] != null) {
            errorMessage = errorJson['message'].toString();
          } else if (response.body.isNotEmpty) {
            errorMessage = 'Failed to create order: ${response.body}';
          }
        } catch (e) {
          // Failed to parse error body, use default message
        }
        print(
          'Server error creating order: ${response.statusCode} - ${response.body}',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network errors
      print('Network error creating order: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Region>> fetchRegions() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:7210/api/Regions'),
    );
    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((item) => Region.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load regions');
    }
  }

  Future<Advertisement> fetchAdvertisement(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/advertisements/$id'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Advertisement.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Advertisement with ID $id not found.');
    } else {
      throw Exception('Failed to load advertisement: ${response.statusCode}');
    }
  }

  // Fetch region name by ID
  Future<String> fetchRegionNameById(int regionId) async {
    final response = await http.get(Uri.parse('$baseUrl/regions/$regionId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['name']; // Adjust based on the actual response format
    } else {
      throw Exception('Failed to load region');
    }
  }
}
