class ServiceCategory {
  final int categoryId;
  final String category;
  final String price; // admin-set customer price (for reference only)
  final List<String> typesOfClothes;

  const ServiceCategory({
    required this.categoryId,
    required this.category,
    required this.price,
    required this.typesOfClothes,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      typesOfClothes: List<String>.from(json['types_of_Clothes'] ?? []),
    );
  }
}

class ServiceModel {
  final int serviceId;
  final String service;
  final int serviceDurationHours;
  final String duration;
  final String description;
  final List<ServiceCategory> categoryList;

  const ServiceModel({
    required this.serviceId,
    required this.service,
    required this.serviceDurationHours,
    required this.duration,
    required this.description,
    required this.categoryList,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: (json['service_id'] as num?)?.toInt() ?? 0,
      service: json['service']?.toString() ?? '',
      serviceDurationHours:
          (json['service_duration_hours'] as num?)?.toInt() ?? 0,
      duration: json['duration']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryList: (json['category_list'] as List<dynamic>? ?? [])
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
