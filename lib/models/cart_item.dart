import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.itemId,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.stock,
    required this.quantity,
    required this.basePrice,
    required this.unitPrice,
    required this.totalPrice,
    required this.discountPercentage,
    this.weightInGrams = 0,
  });

  final String itemId;
  final String productId;
  final String name;
  final String imageUrl;
  final int stock;
  final int quantity;
  final double basePrice;
  final double unitPrice;
  final double totalPrice;
  final double discountPercentage;
  final double weightInGrams;

  factory CartItem.fromApi(Map<String, dynamic> json) => CartItem(
    itemId: json['itemId']?.toString() ?? '',
    productId: json['productId']?.toString() ?? '',
    name: json['productName']?.toString() ?? 'Product',
    imageUrl: json['productCoverUrl']?.toString() ?? '',
    stock: _int(json['productStock']),
    quantity: _int(json['quantity']).clamp(1, 999),
    basePrice: _double(json['basePricePerUnit']),
    unitPrice: _double(json['finalPricePerUnit']),
    totalPrice: _double(json['totalPrice']),
    discountPercentage: _double(json['discountPercentage']),
    weightInGrams: _double(json['weightInGrams']),
  );

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  static double _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  List<Object?> get props => [
    itemId,
    productId,
    name,
    imageUrl,
    stock,
    quantity,
    basePrice,
    unitPrice,
    totalPrice,
    discountPercentage,
    weightInGrams,
  ];
}
