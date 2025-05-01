import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Future<void> saveUserData(String userId, String userType) async {
  await storage.write(key: 'userId', value: userId);
  await storage.write(key: 'userType', value: userType);
}

class AuthService {
  final String apiUrl = 'http://10.0.2.2:7210/api/Auth'; // Your API base URL

  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$apiUrl/login'); // Endpoint for login

    print('Attempting login with username: $username'); // Log login attempt
    print('Sending request to: $url');

    final response = await http.post(
      url,
      body: json.encode({'username': username, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    // Log the response
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Successful login
      print('Login successful!');
      return json.decode(
        response.body,
      ); // Return the response from backend (user info)
    } else {
      // Handle error
      print('Login failed with error: ${response.body}');
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Register method
  Future<Map<String, dynamic>> register(
    String username,
    String password,
    String email,
    String userType,
  ) async {
    final url = Uri.parse('$apiUrl/register'); // Endpoint for registration

    print(
      'Attempting registration with username: $username, email: $email, userType: $userType',
    );
    print('Sending request to: $url');

    final response = await http.post(
      url,
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
        'userType': userType, // Buyer or Seller
      }),
      headers: {'Content-Type': 'application/json'},
    );

    // Log the response
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 201) {
      // Successful registration
      print('Registration successful!');
      return json.decode(response.body);
    } else {
      // Handle error
      print('Registration failed with error: ${response.body}');
      throw Exception('Registration failed: ${response.body}');
    }
  }
}
