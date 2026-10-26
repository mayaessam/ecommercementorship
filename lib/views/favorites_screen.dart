import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../viewmodels/home_cubit.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final products = state.favoriteProducts;
        final wide = MediaQuery.sizeOf(context).width >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 30.h),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR COLLECTION',
                    style: TextStyle(
                      color: const Color(0xFF7B5D36),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Favorites',
                          style: TextStyle(
                            fontSize: 27.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: Container(
                          key: ValueKey(products.length),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE6DF),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: Text(
                            '${products.length} SAVED',
                            style: TextStyle(
                              color: const Color(0xFF7B5D36),
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    products.isEmpty
                        ? 'Keep the pieces you love close.'
                        : 'A considered edit of pieces you love.',
                    style: TextStyle(
                      color: const Color(0xFF77716C),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .025),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: state.isLoading && state.products.isEmpty
                        ? const ProductGridShimmer(key: ValueKey('loading'))
                        : products.isEmpty
                        ? _EmptyFavorites(
                            key: const ValueKey('empty'),
                            loadingError: state.errorMessage,
                          )
                        : GridView.builder(
                            key: const ValueKey('favorites'),
                            itemCount: products.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: wide ? 4 : 2,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                  childAspectRatio: wide ? .60 : .52,
                                ),
                            itemBuilder: (context, index) =>
                                ProductCard(product: products[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({super.key, this.loadingError});

  final String? loadingError;

  @override
  Widget build(BuildContext context) {
    final failed = loadingError != null;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.fromLTRB(22.w, 30.h, 22.w, 26.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0ED),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        children: [
          Container(
            width: 76.w,
            height: 76.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE9DFD4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              failed ? Icons.cloud_off_outlined : Icons.favorite_border_rounded,
              size: 34.sp,
              color: const Color(0xFF7B5D36),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            failed ? 'Could not load products' : 'Your collection starts here',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 7.h),
          Text(
            failed
                ? loadingError!
                : 'Tap the heart on any piece to save it for later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF77716C),
              fontSize: 12.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 19.h),
          FilledButton.icon(
            onPressed: () {
              if (failed) {
                context.read<HomeCubit>().loadProducts();
              } else {
                context.read<HomeCubit>().selectTab(1);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF171719),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9.r),
              ),
            ),
            icon: Icon(
              failed ? Icons.refresh : Icons.arrow_forward,
              size: 17.sp,
            ),
            label: Text(failed ? 'TRY AGAIN' : 'EXPLORE COLLECTION'),
          ),
        ],
      ),
    );
  }
}
