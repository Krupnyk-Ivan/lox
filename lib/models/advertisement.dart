class Advertisement {
  final int id;
  final String title;
  final String description;
  final int categoryId;
  final int regionId;
  final double price;
  final String? imageBase64; // Додаємо поле

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.regionId,
    required this.price,
    this.imageBase64, // Ініціалізація
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      regionId: json['regionId'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageBase64: json['imageBase64'], // Отримання з JSON
    );
  }
}
