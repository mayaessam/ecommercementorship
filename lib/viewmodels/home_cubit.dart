import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_client.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.products,
    this.selectedCategory = 'All',
    this.favoriteIds = const {},
    this.cartCount = 0,
    this.activeTab = 0,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.cartItems = const [],
    this.isCartLoading = false,
    this.cartError,
    this.cartBusyItemIds = const {},
    this.cartBusyProductIds = const {},
    this.isCouponLoading = false,
    this.appliedCoupon,
    this.couponOriginalTotal,
    this.couponDiscountAmount,
    this.couponFinalTotal,
  });

  final List<Product> products;
  final String selectedCategory;
  final Set<String> favoriteIds;
  final int cartCount;
  final int activeTab;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> cartItems;
  final bool isCartLoading;
  final String? cartError;
  final Set<String> cartBusyItemIds;
  final Set<String> cartBusyProductIds;
  final bool isCouponLoading;
  final String? appliedCoupon;
  final double? couponOriginalTotal;
  final double? couponDiscountAmount;
  final double? couponFinalTotal;

  double get cartSubtotal =>
      cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get cartTotal => couponFinalTotal ?? cartSubtotal;

  CartItem? cartItemForProduct(String productId) {
    for (final item in cartItems) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  int cartQuantityForProduct(String productId) =>
      cartItemForProduct(productId)?.quantity ?? 0;

  List<Product> get visibleProducts {
    return products.where((product) {
      final categoryMatches =
          selectedCategory == 'All' || product.category == selectedCategory;

      final query = searchQuery.trim().toLowerCase();

      final searchMatches =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);

      return categoryMatches && searchMatches;
    }).toList();
  }

  List<Product> get favoriteProducts {
    return products
        .where((product) => favoriteIds.contains(product.id))
        .toList();
  }

  HomeState copyWith({
    String? selectedCategory,
    Set<String>? favoriteIds,
    int? cartCount,
    int? activeTab,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<Product>? products,
    List<CartItem>? cartItems,
    bool? isCartLoading,
    String? cartError,
    bool clearCartError = false,
    Set<String>? cartBusyItemIds,
    Set<String>? cartBusyProductIds,
    bool? isCouponLoading,
    String? appliedCoupon,
    bool clearCoupon = false,
    double? couponOriginalTotal,
    double? couponDiscountAmount,
    double? couponFinalTotal,
  }) {
    return HomeState(
      products: products ?? this.products,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      cartCount: cartCount ?? this.cartCount,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cartItems: cartItems ?? this.cartItems,
      isCartLoading: isCartLoading ?? this.isCartLoading,
      cartError: clearCartError ? null : (cartError ?? this.cartError),
      cartBusyItemIds: cartBusyItemIds ?? this.cartBusyItemIds,
      cartBusyProductIds: cartBusyProductIds ?? this.cartBusyProductIds,
      isCouponLoading: isCouponLoading ?? this.isCouponLoading,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      couponOriginalTotal: clearCoupon
          ? null
          : (couponOriginalTotal ?? this.couponOriginalTotal),
      couponDiscountAmount: clearCoupon
          ? null
          : (couponDiscountAmount ?? this.couponDiscountAmount),
      couponFinalTotal: clearCoupon
          ? null
          : (couponFinalTotal ?? this.couponFinalTotal),
    );
  }

  @override
  List<Object?> get props => [
    products,
    selectedCategory,
    favoriteIds,
    cartCount,
    activeTab,
    searchQuery,
    isLoading,
    errorMessage,
    cartItems,
    isCartLoading,
    cartError,
    cartBusyItemIds,
    cartBusyProductIds,
    isCouponLoading,
    appliedCoupon,
    couponOriginalTotal,
    couponDiscountAmount,
    couponFinalTotal,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({ApiClient? api, List<Product> initialProducts = const []})
    : _api = api ?? ApiClient(),
      super(HomeState(products: initialProducts));

  final ApiClient _api;

  Future<void> loadProducts() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final products = await _api.products();
      try {
        final cats = await _api.categories();
        _categories = [
          'All',
          ...cats.map((e) => e['name'].toString()).where((e) => e.isNotEmpty),
        ];
      } catch (_) {
        // Categories currently require authentication on the API. Keep product
        // browsing available by deriving the visible filters from public data.
        _categories = [
          'All',
          ...products.map((product) => product.category).toSet(),
        ];
      }
      emit(
        state.copyWith(products: products, isLoading: false, clearError: true),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: _message(error)));
    }
  }

  List<String> _categories = const [
    'All',
    'Leather Bags',
    'Fine Jewelry',
    'Watches',
    'Accessories',
  ];
  List<String> get categories => _categories;

  static String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.response == null) {
        if (kIsWeb) {
          return 'The API blocks browser requests. Enable CORS on the API server.';
        }
        return 'Could not connect. Check your internet and try again.';
      }
      return 'The server returned an error (${error.response?.statusCode}).';
    }
    return 'Could not load products. Please try again.';
  }

  void selectCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  void toggleFavorite(String productId) {
    final updated = Set<String>.from(state.favoriteIds);

    if (!updated.add(productId)) {
      updated.remove(productId);
    }

    emit(state.copyWith(favoriteIds: updated));
  }

  Future<void> addToCart(String productId) async {
    final busyIds = Set<String>.from(state.cartBusyProductIds)..add(productId);
    emit(state.copyWith(cartBusyProductIds: busyIds));
    try {
      await _api.addCartItem(productId);
      await loadCart();
    } finally {
      final latest = Set<String>.from(state.cartBusyProductIds)
        ..remove(productId);
      if (!isClosed) emit(state.copyWith(cartBusyProductIds: latest));
    }
  }

  Future<void> adjustCartProduct(String productId, int difference) async {
    final item = state.cartItemForProduct(productId);
    if (item == null) {
      if (difference > 0) await addToCart(productId);
      return;
    }
    await updateCartQuantity(item, item.quantity + difference);
  }

  Future<void> loadCart() async {
    if (!await _api.hasSession()) {
      if (!isClosed) {
        emit(
          state.copyWith(
            cartItems: const [],
            cartCount: 0,
            isCartLoading: false,
            clearCartError: true,
            clearCoupon: true,
          ),
        );
      }
      return;
    }
    if (!isClosed) {
      emit(state.copyWith(isCartLoading: true, clearCartError: true));
    }
    try {
      await _readCart();
      if (!isClosed) emit(state.copyWith(isCartLoading: false));
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isCartLoading: false, cartError: _message(error)));
      }
    }
  }

  Future<void> _readCart() async {
    final response = await _api.cart();
    final rawItems = response['cartItems'] as List? ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map((item) => CartItem.fromApi(Map<String, dynamic>.from(item)))
        .toList();
    final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
    if (!isClosed) {
      emit(
        state.copyWith(
          cartItems: items,
          cartCount: count,
          clearCartError: true,
        ),
      );
    }
  }

  Future<void> updateCartQuantity(CartItem item, int quantity) async {
    if (quantity < 1) return removeCartItem(item);
    await _withCartItemBusy(item.itemId, () async {
      await _api.updateCartItem(item.itemId, quantity);
      await _readCart();
      if (!isClosed) emit(state.copyWith(clearCoupon: true));
    });
  }

  Future<void> removeCartItem(CartItem item) async {
    await _withCartItemBusy(item.itemId, () async {
      await _api.deleteCartItem(item.itemId);
      await _readCart();
      if (!isClosed) emit(state.copyWith(clearCoupon: true));
    });
  }

  Future<void> _withCartItemBusy(
    String itemId,
    Future<void> Function() action,
  ) async {
    final busyIds = Set<String>.from(state.cartBusyItemIds)..add(itemId);
    emit(state.copyWith(cartBusyItemIds: busyIds, clearCartError: true));
    try {
      await action();
    } finally {
      final latest = Set<String>.from(state.cartBusyItemIds)..remove(itemId);
      if (!isClosed) emit(state.copyWith(cartBusyItemIds: latest));
    }
  }

  Future<void> applyCartCoupon(String code) async {
    emit(state.copyWith(isCouponLoading: true, clearCartError: true));
    try {
      final response = await _api.applyCoupon(code) as Map;
      if (isClosed) return;
      emit(
        state.copyWith(
          isCouponLoading: false,
          appliedCoupon:
              (response['coupon'] as Map?)?['code']?.toString() ?? code,
          couponOriginalTotal: _number(response['originalTotal']),
          couponDiscountAmount: _number(response['discountAmount']),
          couponFinalTotal: _number(response['finalTotal']),
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isCouponLoading: false));
      }
      rethrow;
    }
  }

  void clearCartCoupon() {
    emit(state.copyWith(clearCoupon: true));
  }

  static double _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  void selectTab(int index) {
    emit(state.copyWith(activeTab: index));
  }
}
