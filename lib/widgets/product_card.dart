import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../viewmodels/home_cubit.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  static const _ink = Color(0xFF171719);
  static const _muted = Color(0xFF5B5B5F);
  static const _gold = Color(0xFF7B5D36);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.favoriteIds != current.favoriteIds ||
          previous.cartItems != current.cartItems ||
          previous.cartBusyItemIds != current.cartBusyItemIds ||
          previous.cartBusyProductIds != current.cartBusyProductIds,
      builder: (context, state) {
        final isFavorite = state.favoriteIds.contains(product.id);
        final cartItem = state.cartItemForProduct(product.id);
        final cartQuantity = cartItem?.quantity ?? 0;
        final cartBusy =
            state.cartBusyProductIds.contains(product.id) ||
            (cartItem != null &&
                state.cartBusyItemIds.contains(cartItem.itemId));
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty)
                      Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ProductPlaceholder(),
                      )
                    else if (product.imageAsset.isNotEmpty)
                      Image.asset(
                        product.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ProductPlaceholder(),
                      )
                    else
                      const _ProductPlaceholder(),
                    if (product.rating != null)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          color: Colors.white.withValues(alpha: .94),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 13, color: _gold),
                              SizedBox(width: 2.w),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (product.badge != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 4.h,
                          ),
                          color: _gold,
                          child: Text(
                            product.badge!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 7.h,
                      right: 7.w,
                      child: Material(
                        color: Colors.white.withValues(alpha: .95),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.read<HomeCubit>().toggleFavorite(
                            product.id,
                          ),
                          child: SizedBox(
                            width: 36.w,
                            height: 36.w,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.elasticOut,
                                    ),
                                    child: child,
                                  ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(isFavorite),
                                size: 19.sp,
                                color: isFavorite
                                    ? Colors.red.shade700
                                    : _muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(9.w, 8.h, 8.w, 7.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 13.sp,
                        height: 1.18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.price}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                        _cartQuantityControl(
                          context,
                          quantity: cartQuantity,
                          busy: cartBusy,
                          canIncrement:
                              cartItem == null ||
                              cartItem.stock <= 0 ||
                              cartQuantity < cartItem.stock,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cartQuantityControl(
    BuildContext context, {
    required int quantity,
    required bool busy,
    required bool canIncrement,
  }) {
    if (busy) {
      return SizedBox(
        width: 30.w,
        height: 30.w,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (quantity == 0) {
      return _quantityButton(
        context,
        icon: Icons.add,
        onPressed: () => _changeCartQuantity(context, 1),
      );
    }
    return Container(
      height: 30.w,
      decoration: BoxDecoration(
        color: const Color(0xFFECEBE9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            context,
            icon: Icons.remove,
            onPressed: () => _changeCartQuantity(context, -1),
            compact: true,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                style: TextStyle(
                  color: _ink,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _quantityButton(
            context,
            icon: Icons.add,
            onPressed: canIncrement
                ? () => _changeCartQuantity(context, 1)
                : null,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    bool compact = false,
  }) => Material(
    color: compact ? Colors.transparent : const Color(0xFFECEBE9),
    borderRadius: BorderRadius.circular(5.r),
    child: InkWell(
      borderRadius: BorderRadius.circular(5.r),
      onTap: onPressed,
      child: SizedBox(
        width: compact ? 27.w : 30.w,
        height: 30.w,
        child: Icon(
          icon,
          size: compact ? 14.sp : 18.sp,
          color: onPressed == null ? _muted : _ink,
        ),
      ),
    ),
  );

  Future<void> _changeCartQuantity(BuildContext context, int difference) async {
    try {
      await context.read<HomeCubit>().adjustCartProduct(product.id, difference);
    } catch (error) {
      if (!context.mounted) return;
      final unauthorized =
          error is DioException && error.response?.statusCode == 401;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unauthorized
                ? 'Sign in to add items to your cart.'
                : 'Could not update this item in your cart.',
          ),
        ),
      );
    }
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFF1ECE5),
    child: Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 42,
        color: Color(0xFF9A8265),
      ),
    ),
  );
}
