class Advertisement {
  final int id;
  final String title;
  final String description;
  final int categoryId; // Storing category ID
  final int regionId; // Storing region ID instead of region name
  final double price;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId, // Updated constructor for category ID
    required this.regionId, // Updated constructor for region ID
    required this.price,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? 0, // Mapping to categoryId
      regionId: json['regionId'] ?? 0, // Mapping to regionId
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
