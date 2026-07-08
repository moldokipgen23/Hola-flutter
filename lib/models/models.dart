class Category {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? image;
  final bool isActive;
  final bool isFeatured;
  final int businessesCount;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.image,
    this.isActive = true,
    this.isFeatured = false,
    this.businessesCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      image: json['image'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      businessesCount: json['businesses_count'] ?? 0,
    );
  }
}

class Business {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? address;
  final String? locality;
  final String? district;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final List<String> photos;
  final Map<String, dynamic>? workingHours;
  final bool isActive;
  final bool isFeatured;
  final int viewsCount;
  final int savesCount;
  final int qualityScore;
  final Category? category;
  final String? claimStatus;
  final String? distance;
  final bool? isSaved;

  Business({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.address,
    this.locality,
    this.district,
    this.lat,
    this.lng,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.photos = const [],
    this.workingHours,
    this.isActive = true,
    this.isFeatured = false,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.qualityScore = 0,
    this.category,
    this.claimStatus,
    this.distance,
    this.isSaved,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      address: json['address'],
      locality: json['locality'],
      district: json['district'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      website: json['website'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      workingHours: json['working_hours'],
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      viewsCount: json['views_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      qualityScore: json['quality_score'] ?? 0,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      claimStatus: json['claim_status'],
      distance: json['distance']?.toString(),
      isSaved: json['is_saved'],
    );
  }
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final double? price;
  final String? availability;
  final Business? business;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    this.price,
    this.availability,
    this.business,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      image: json['image'],
      price: json['price']?.toDouble(),
      availability: json['availability'],
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
    );
  }
}
