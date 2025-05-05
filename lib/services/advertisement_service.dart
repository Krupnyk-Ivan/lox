import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/advertisement.dart';

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
