import 'package:flutter/material.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';

class CreateFeedbackPage extends StatefulWidget {
  final int adId;
  final int buyerId;

  const CreateFeedbackPage({
    super.key,
    required this.adId,
    required this.buyerId,
  });

  @override
  State<CreateFeedbackPage> createState() => _CreateFeedbackPageState();
}

class _CreateFeedbackPageState extends State<CreateFeedbackPage> {
  final TextEditingController _commentController = TextEditingController();
  int? _rating;

  final FeedbackService _service = FeedbackService();

  Future<void> _submitFeedback() async {
    final feedback = FeedbackModel(
      commentText: _commentController.text,
      createdDate: DateTime.now().toIso8601String(),
      rating: _rating,
      adId: widget.adId,
      buyerId: widget.buyerId,
    );

    try {
      await _service.createFeedback(feedback);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feedback submitted')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Comment'),
              maxLines: 3,
            ),
            DropdownButton<int>(
              value: _rating,
              hint: Text('Rating'),
              items:
                  [1, 2, 3, 4, 5]
                      .map(
                        (val) =>
                            DropdownMenuItem(value: val, child: Text('$val')),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitFeedback, child: Text('Submit')),
          ],
        ),
      ),
    );
  }
}
