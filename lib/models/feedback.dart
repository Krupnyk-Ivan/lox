class FeedbackModel {
  final int? id;
  final String? commentText;
  final String createdDate;
  final int? rating;
  final int? buyerId;
  final int? adId;

  FeedbackModel({
    this.id,
    this.commentText,
    required this.createdDate,
    this.rating,
    this.buyerId,
    this.adId,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      commentText: json['commentText'],
      createdDate: json['createdDate'],
      rating: json['rating'],
      buyerId: json['buyerId'],
      adId: json['adId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentText': commentText,
      'createdDate': createdDate,
      'rating': rating,
      'buyerId': buyerId,
      'adId': adId,
    };
  }
}
