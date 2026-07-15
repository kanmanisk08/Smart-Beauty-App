class Service {
  final String id;
  final String name;
  final String category;
  final double price;
  final int duration;
  final String image;
  final String description;
  bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    required this.image,
    required this.description,
    this.isActive = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as int,
      image: json['image'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'duration': duration,
      'image': image,
      'description': description,
      'isActive': isActive,
    };
  }
}
