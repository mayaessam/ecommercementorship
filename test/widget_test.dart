import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommercementorship/models/product.dart';
import 'package:ecommercementorship/viewmodels/home_cubit.dart';
import 'package:ecommercementorship/views/home_screen.dart';

void main() {
  testWidgets('home screen renders and bottom navigation opens categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(414, 896),
        builder: (context, child) => BlocProvider(
          create: (_) => HomeCubit(
            initialProducts: const [
              Product(
                id: 'product-1',
                brand: 'ORANGE',
                name: 'Genuine Leather Jacket',
                price: 2499,
                imageAsset: '',
                category: 'clothes',
                rating: 0,
                badge: '15% OFF',
              ),
              Product(
                id: 'product-2',
                brand: 'AURA',
                name: 'Aviator Sunglasses',
                price: 1200,
                imageAsset: '',
                category: 'accessories',
              ),
            ],
          ),
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AURA'), findsWidgets);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('CATEGORIES'), findsOneWidget);
    expect(find.text('CLOTHES'), findsOneWidget);
    expect(find.text('ACCESSORIES'), findsOneWidget);

    await tester.tap(find.text('CATEGORIES'));
    await tester.pumpAndSettle();

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
