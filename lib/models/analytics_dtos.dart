class CategoryCountDto {
  final int? categoryId;
  final String? categoryName;
  final int count;

  CategoryCountDto({
    required this.categoryId,
    required this.categoryName,
    required this.count,
  });

  factory CategoryCountDto.fromJson(Map<String, dynamic> json) {
    return CategoryCountDto(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      count:
          json['count'] is int
              ? json['count']
              : int.parse(json['count'].toString()), // Ensure int parsing
    );
  }
}

class RegionCountDto {
  final int? regionId;
  final String? regionName;
  final int count;

  RegionCountDto({
    required this.regionId,
    required this.regionName,
    required this.count,
  });

  factory RegionCountDto.fromJson(Map<String, dynamic> json) {
    return RegionCountDto(
      regionId: json['regionId'],
      regionName: json['regionName'],
      count:
          json['count'] is int
              ? json['count']
              : int.parse(json['count'].toString()), // Ensure int parsing
    );
  }
}
