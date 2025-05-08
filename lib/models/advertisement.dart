class Advertisement {
  final int id;
  final String title;
  final String description;
  final int categoryId;
  final int regionId;
  final double price;
  final String? imageBase64;
  final DateTime createdDate;
  final int sellerId; // ✅ Додано
  bool isFavorite;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.regionId,
    required this.price,
    this.imageBase64,
    required this.createdDate,
    required this.sellerId, // ✅ Додано
    this.isFavorite = false,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'regionId': regionId,
      'sellerId': sellerId,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    // Створюємо Map. Включаємо тільки ті поля, які можуть бути змінені клієнтом
    // та ID оголошення, щоб бек-енд знав, що оновлювати.
    final Map<String, dynamic> data = {
      'id':
          id, // !!! ID оголошення ОБОВ'ЯЗКОВО потрібен бек-енду для ідентифікації ресурсу !!!
      'title': title, // Заголовок
      'description': description, // Опис
      'price': price, // Ціна
      'categoryId': categoryId, // ID категорії
      'regionId': regionId,
      'sellerId': sellerId,

      'imageBase64': imageBase64,
      'image_data': imageBase64,
    };

    return data;
  }

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      regionId: json['regionId'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageBase64: json['imageBase64'],
      createdDate: DateTime.parse(json['createdDate']),
      sellerId: json['sellerId'] ?? 0, // ✅ Зчитуємо sellerId
    );
  }
}
