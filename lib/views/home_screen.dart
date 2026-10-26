import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../viewmodels/home_cubit.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'account_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (previous, current) =>
                    previous.activeTab != current.activeTab,
                builder: (context, state) {
                  final page = switch (state.activeTab) {
                    1 => const CategoriesScreen(),
                    2 => const FavoritesScreen(),
                    3 => const AccountScreen(),
                    _ => const _HomeContent(),
                  };
                  return AnimatedSwitcher(
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previousChildren, ?currentChild],
                    ),
                    duration: const Duration(milliseconds: 280),
                    reverseDuration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
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
                    child: KeyedSubtree(
                      key: ValueKey(state.activeTab),
                      child: page,
                    ),
                  );
                },
              ),
            ),
            const _BottomNavigation(),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// HOME CONTENT
// --------------------------------------------------

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28.w, 10.h, 28.w, 24.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 920 : 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeroBanner(),
                  SizedBox(height: 18.h),
                  const _CategorySection(),
                  SizedBox(height: 22.h),
                  const _CuratedHeading(),
                  SizedBox(height: 10.h),

                  BlocBuilder<HomeCubit, HomeState>(
                    buildWhen: (previous, current) =>
                        previous.products != current.products ||
                        previous.isLoading != current.isLoading ||
                        previous.errorMessage != current.errorMessage ||
                        previous.selectedCategory != current.selectedCategory ||
                        previous.searchQuery != current.searchQuery,
                    builder: (context, state) {
                      final columns = wide ? 4 : 2;
                      final products = state.visibleProducts;

                      if (state.isLoading && products.isEmpty) {
                        return const ProductGridShimmer(itemCount: 4);
                      }
                      if (state.errorMessage != null && products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: context
                                    .read<HomeCubit>()
                                    .loadProducts,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (products.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No products found.',
                              style: TextStyle(color: Color(0xFF626166)),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        itemCount: products.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: wide ? .60 : .52,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: products[index]);
                        },
                      );
                    },
                  ),

                  SizedBox(height: 14.h),
                  const _DeliveryCard(),
                  SizedBox(height: 18.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// HEADER
// --------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF9F7),
      padding: EdgeInsets.fromLTRB(28.w, 14.h, 28.w, 12.h),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 14.sp, color: const Color(0xFF272629)),
          SizedBox(width: 7.w),
          Text(
            'AURA',
            style: TextStyle(
              fontSize: 23.sp,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111113),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showMessage(context, 'Search products'),
            icon: Icon(Icons.search, size: 24.sp),
            color: const Color(0xFF202023),
          ),
          BlocBuilder<HomeCubit, HomeState>(
            buildWhen: (a, b) => a.cartCount != b.cartCount,
            builder: (context, state) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const CartScreen(),
                      ),
                    ),
                    icon: Icon(Icons.shopping_bag_outlined, size: 23.sp),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B5D36),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${state.cartCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: 6.w),
          CircleAvatar(
            radius: 17.r,
            backgroundColor: const Color(0xFFE3D9CC),
            child: Icon(
              Icons.person,
              color: const Color(0xFF7B5D36),
              size: 21.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// HERO BANNER
// --------------------------------------------------

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: double.infinity,
        height: 320.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B6C4C), Color(0xFF211C19)],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .05),
                    Colors.black.withValues(alpha: .15),
                    Colors.black.withValues(alpha: .82),
                  ],
                  stops: const [0, .38, 1],
                ),
              ),
            ),
            Positioned(
              left: 24.w,
              right: 18.w,
              bottom: 24.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0D7AD),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '✦ ÉDITION LIMITÉE',
                      style: TextStyle(
                        color: const Color(0xFF76562F),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'New Season Capsule',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30.sp,
                      height: 1.05,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -.7,
                    ),
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    'Handcrafted minimal leather goods &\n'
                    'timeless jewelry shaped by architecture.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .86),
                      fontSize: 14.sp,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  FilledButton(
                    onPressed: () {
                      _showMessage(context, 'Explore the collection');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF202023),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 13.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SHOP COLLECTION',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .7,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Icon(Icons.arrow_forward, size: 17.sp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CATEGORY CHIPS
// --------------------------------------------------

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (a, b) =>
          a.selectedCategory != b.selectedCategory || a.products != b.products,
      builder: (context, state) {
        final categories = <String>{
          'All',
          ...state.products.map((product) => product.category),
        }.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'EXPLORE ATELIER',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF4D4B4A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const Spacer(),
                Text(
                  '${categories.length - 1} CATEGORIES',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF7B5D36),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),
            SizedBox(
              height: 38.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = state.selectedCategory == category;

                  final icon = switch (category) {
                    'All' => Icons.stars_outlined,
                    'Leather Bags' => Icons.shopping_bag_outlined,
                    'Fine Jewelry' => Icons.diamond_outlined,
                    _ => Icons.watch_outlined,
                  };

                  return ChoiceChip(
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      context.read<HomeCubit>().selectCategory(category);
                    },
                    avatar: Icon(
                      icon,
                      size: 14.sp,
                      color: selected ? Colors.white : const Color(0xFF555459),
                    ),
                    label: Text(category.toUpperCase()),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF4D4B50),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                    backgroundColor: const Color(0xFFF0EFED),
                    selectedColor: const Color(0xFF111113),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------
// CURATED PRODUCTS HEADING
// --------------------------------------------------

class _CuratedHeading extends StatelessWidget {
  const _CuratedHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curated For You',
                style: TextStyle(
                  fontSize: 22.sp,
                  color: const Color(0xFF171719),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Handcrafted essentials made in limited\nbatches',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF5C5A5E),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            _showMessage(context, 'Showing all 28 products');
          },
          child: Row(
            children: [
              Text(
                'VIEW\n28',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFF7B5D36),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: const Color(0xFF7B5D36),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// DELIVERY CARD
// --------------------------------------------------

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCA8),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: const Color(0xFF7B5D36),
                  size: 25.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4DDD4),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'ATELIER SERVICE',
                        style: TextStyle(
                          color: const Color(0xFF7B5D36),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Complimentary Express Courier',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: const Color(0xFF242326),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Carbon-neutral delivery across all orders '
                      'exceeding \$150. Includes bespoke packaging '
                      'and signature gift wrap.',
                      style: TextStyle(
                        color: const Color(0xFF5B595D),
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 13.sp,
                color: const Color(0xFF7B5D36),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  'THRESHOLD UNLOCKED',
                  style: TextStyle(
                    color: const Color(0xFF7B5D36),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
              Text(
                '\$240 / \$150',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: const LinearProgressIndicator(
              value: 1,
              minHeight: 5,
              backgroundColor: Color(0xFFDED8D0),
              valueColor: AlwaysStoppedAnimation(Color(0xFF7B5D36)),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// BOTTOM NAVIGATION
// --------------------------------------------------

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  static const items = [
    (Icons.home_outlined, 'HOME'),
    (Icons.grid_view_outlined, 'CATEGORIES'),
    (Icons.favorite_border, 'FAVORITES'),
    (Icons.person_outline, 'ACCOUNT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F7),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: .06)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 18.h),
      child: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (a, b) =>
            a.activeTab != b.activeTab || a.favoriteIds != b.favoriteIds,
        builder: (context, state) {
          return Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = state.activeTab == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    context.read<HomeCubit>().selectTab(index);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.14 : 1,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                item.$1,
                                size: 22.sp,
                                color: selected
                                    ? const Color(0xFF111113)
                                    : const Color(0xFF5E5D61),
                              ),
                            ),
                            if (index == 2 && state.favoriteIds.isNotEmpty)
                              Positioned(
                                top: -7,
                                right: -11,
                                child: Container(
                                  padding: EdgeInsets.all(3.w),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7B5D36),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${state.favoriteIds.length}',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF111113)
                                : const Color(0xFF555459),
                            fontSize: selected ? 9.sp : 8.5.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                          child: Text(item.$2),
                        ),
                        if (selected)
                          Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Container(
                              width: 4.w,
                              height: 4.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7B5D36),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------
// SNACKBAR HELPER
// --------------------------------------------------

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
