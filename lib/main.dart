import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'viewmodels/home_cubit.dart';
import 'views/home_screen.dart';

void main() {
  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Use a device viewport as the reference size. The previous full-page
      // height scaled component heights down to roughly half on phones.
      designSize: const Size(414, 896),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocProvider(
          create: (_) => HomeCubit()
            ..loadProducts()
            ..loadCart(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AURA',
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFFAF9F7),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF7B5D36),
                brightness: Brightness.light,
              ),
              fontFamily: 'Roboto',
            ),
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
