import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feedback.dart';

class FeedbackService {
  final String baseUrl = 'http://10.0.2.2:7210/api/Feedbacks';

  Future<List<FeedbackModel>> fetchFeedbacks() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => FeedbackModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load feedbacks');
    }
  }

  Future<void> createFeedback(FeedbackModel feedback) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(feedback.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create feedback');
    }
  }
}
