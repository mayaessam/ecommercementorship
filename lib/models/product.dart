import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.price,
    required this.imageAsset,
    required this.category,
    this.imageUrl,
    this.rating,
    this.badge,
  });

  final String id;
  final String brand;
  final String name;
  final int price;
  final String imageAsset;
  final String category;
  final String? imageUrl;
  final double? rating;
  final String? badge;

  factory Product.fromApi(Map<String, dynamic> json) {
    final categories = (json['categories'] as List? ?? const [])
        .whereType<String>();
    final discount = (json['discountPercentage'] as num?)?.toInt() ?? 0;
    return Product(
      id: json['id']?.toString() ?? '',
      brand: json['color']?.toString() ?? 'AURA COLLECTION',
      name: json['name']?.toString() ?? 'Product',
      price: ((json['price'] as num?) ?? 0).round(),
      imageAsset: '',
      imageUrl: json['coverPictureUrl']?.toString(),
      category: categories.isEmpty ? 'Accessories' : categories.first,
      rating: (json['rating'] as num?)?.toDouble(),
      badge: discount > 0 ? '$discount% OFF' : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brand,
    name,
    price,
    imageAsset,
    category,
    rating,
    badge,
    imageUrl,
  ];
}
