import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final slide = (_controller.value * 2.4) - 1.2;
        return LinearGradient(
          begin: Alignment(slide - 1, 0),
          end: Alignment(slide + 1, 0),
          colors: const [
            Color(0xFFE9E5E1),
            Color(0xFFF8F6F4),
            Color(0xFFE9E5E1),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds);
      },
      child: child,
    ),
  );
}

class ProductGridShimmer extends StatelessWidget {
  const ProductGridShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return ShimmerLoading(
      child: GridView.builder(
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: wide ? 4 : 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: wide ? .60 : .52,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 7, child: ColoredBox(color: Colors.white)),
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 52.w, height: 8.h),
                    SizedBox(height: 8.h),
                    _bar(width: double.infinity, height: 11.h),
                    SizedBox(height: 5.h),
                    _bar(width: 74.w, height: 11.h),
                    SizedBox(height: 10.h),
                    _bar(width: double.infinity, height: 16.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _bar({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
      );
}

class AccountShimmer extends StatelessWidget {
  const AccountShimmer({super.key});

  @override
  Widget build(BuildContext context) => ShimmerLoading(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 32.r, backgroundColor: Colors.white),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 150.w, height: 15.h),
                    SizedBox(height: 10.h),
                    _line(width: 190.w, height: 11.h),
                    SizedBox(height: 10.h),
                    _line(width: 80.w, height: 9.h),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),
        Container(
          height: 150.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ],
    ),
  );

  static Widget _line({required double width, required double height}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
      );
}
