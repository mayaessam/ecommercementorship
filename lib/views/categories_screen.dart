import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../viewmodels/home_cubit.dart';
import '../widgets/product_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final wide = MediaQuery.sizeOf(context).width >= 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISCOVER AURA',
                    style: TextStyle(
                      color: const Color(0xFF7B5D36),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  TextField(
                    onChanged: context.read<HomeCubit>().setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: context.read<HomeCubit>().clearSearch,
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: context.read<HomeCubit>().categories.map((
                      category,
                    ) {
                      final selected = state.selectedCategory == category;

                      return ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) {
                          context.read<HomeCubit>().selectCategory(category);
                        },
                        selectedColor: const Color(0xFF171719),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF454348),
                          fontSize: 11.sp,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 20.h),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.selectedCategory == 'All'
                              ? 'All products'
                              : state.selectedCategory,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${state.visibleProducts.length} items',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  if (state.visibleProducts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Color(0xFF7B5D36),
                            ),
                            SizedBox(height: 10),
                            Text('No products found'),
                            Text('Try another category or keyword.'),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      itemCount: state.visibleProducts.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: wide ? 0.60 : 0.52,
                      ),
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: state.visibleProducts[index],
                        );
                      },
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
