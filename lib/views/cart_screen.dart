import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cart_item.dart';
import '../services/api_client.dart';
import '../viewmodels/home_cubit.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _api = ApiClient();
  final _couponController = TextEditingController();
  bool _checkingSession = true;
  bool _signedIn = false;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final signedIn = await _api.hasSession();
    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _checkingSession = false;
    });
    if (signedIn) await context.read<HomeCubit>().loadCart();
  }

  Future<void> _signIn() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));
    if (mounted) await _load();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      _message('Enter a coupon code first.');
      return;
    }
    try {
      await context.read<HomeCubit>().applyCartCoupon(code);
      if (!mounted) return;
      _message('Coupon applied.');
    } catch (error) {
      _message(_api.errorMessage(error));
    }
  }

  Future<void> _checkout() async {
    final homeCubit = context.read<HomeCubit>();
    final couponCode = homeCubit.state.appliedCoupon;
    setState(() => _checkingOut = true);
    try {
      final addresses = await _api.addresses();
      var validAddresses = addresses
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      if (validAddresses.isEmpty) {
        final created = await _createAddress();
        if (created == null) return;
        validAddresses = [created];
      }
      if (!mounted) return;
      final address = await _selectAddress(validAddresses);
      if (address == null) return;
      if (!mounted) return;

      final response = await _api.checkout(
        addressId: address['id'].toString(),
        paymentMethod: 'Stripe',
        couponCode: couponCode,
      );
      final result = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      final paymentUrl = result['unifiedCheckoutUrl']?.toString();
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final uri = Uri.tryParse(paymentUrl);
        if (uri == null || !uri.hasScheme) {
          _message('The payment link returned by the server is invalid.');
        } else if (!await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        )) {
          _message('Could not open the payment page.');
        } else {
          _message('Checkout created. Complete payment in your browser.');
        }
      } else {
        _message(result['message']?.toString() ?? 'Checkout created.');
      }
      if (mounted) {
        homeCubit.clearCartCoupon();
        await homeCubit.loadCart();
      }
    } catch (error) {
      _message(_api.errorMessage(error));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<Map<String, dynamic>?> _selectAddress(
    List<Map<String, dynamic>> addresses,
  ) => showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFAF9F7),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose delivery address',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            ...addresses.map(
              (address) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined, color: _gold),
                title: Text(
                  [address['street'], address['apartment']]
                      .where(
                        (part) => part != null && part.toString().isNotEmpty,
                      )
                      .join(', '),
                ),
                subtitle: Text(
                  [address['city'], address['state'], address['phoneNumber']]
                      .where(
                        (part) => part != null && part.toString().isNotEmpty,
                      )
                      .join(' · '),
                ),
                onTap: () => Navigator.pop(context, address),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<Map<String, dynamic>?> _createAddress() async {
    final state = TextEditingController();
    final city = TextEditingController();
    final street = TextEditingController();
    final apartment = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add delivery address'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _addressField(state, 'State / region'),
                _addressField(city, 'City'),
                _addressField(street, 'Street'),
                _addressField(
                  apartment,
                  'Apartment (optional)',
                  required: false,
                ),
                _addressField(phone, 'Phone number'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final response = await _api.createAddress({
                  'state': state.text.trim(),
                  'city': city.text.trim(),
                  'street': street.text.trim(),
                  'apartment': apartment.text.trim(),
                  'phoneNumber': phone.text.trim(),
                  'notes': '',
                });
                if (dialogContext.mounted && response is Map) {
                  Navigator.pop(
                    dialogContext,
                    Map<String, dynamic>.from(response),
                  );
                }
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(_api.errorMessage(error))),
                );
              }
            },
            child: const Text('SAVE ADDRESS'),
          ),
        ],
      ),
    );
    state.dispose();
    city.dispose();
    street.dispose();
    apartment.dispose();
    phone.dispose();
    return result;
  }

  Widget _addressField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF9F7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome, size: 15.sp, color: _ink),
            SizedBox(width: 7.w),
            Text(
              'AURA',
              style: TextStyle(
                color: _ink,
                fontSize: 23.sp,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final items = state.cartItems;
            final busy = state.cartBusyItemIds;
            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: _gold,
                    onRefresh: context.read<HomeCubit>().loadCart,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR SELECTION',
                                    style: TextStyle(
                                      color: _gold,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Shopping bag',
                                    style: TextStyle(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${state.cartCount} ${state.cartCount == 1 ? 'ITEM' : 'ITEMS'}',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 17.h),
                        if (_checkingSession ||
                            state.isCartLoading && items.isEmpty)
                          const _CartShimmer()
                        else if (!_signedIn)
                          _signedOut()
                        else if (state.cartError != null && items.isEmpty)
                          _errorState(state.cartError!)
                        else if (items.isEmpty)
                          _emptyState()
                        else ...[
                          ...items.map(
                            (item) => _CartItemCard(
                              item: item,
                              busy: busy.contains(item.itemId),
                              onIncrement:
                                  item.stock > 0 && item.quantity < item.stock
                                  ? () => _runCartAction(
                                      context,
                                      () => context
                                          .read<HomeCubit>()
                                          .updateCartQuantity(
                                            item,
                                            item.quantity + 1,
                                          ),
                                    )
                                  : null,
                              onDecrement: () => item.quantity == 1
                                  ? _confirmRemove(context, item)
                                  : _runCartAction(
                                      context,
                                      () => context
                                          .read<HomeCubit>()
                                          .updateCartQuantity(
                                            item,
                                            item.quantity - 1,
                                          ),
                                    ),
                              onRemove: () => _confirmRemove(context, item),
                            ),
                          ),
                          SizedBox(height: 7.h),
                          _couponPanel(state),
                          SizedBox(height: 15.h),
                          _summary(state),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_signedIn && items.isNotEmpty && !state.isCartLoading)
                  _checkoutBar(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _signedOut() => _infoCard(
    icon: Icons.lock_outline,
    title: 'Sign in to see your cart',
    description:
        'Your bag is saved to your account and ready whenever you are.',
    buttonLabel: 'SIGN IN',
    onPressed: _signIn,
  );

  Widget _emptyState() => _infoCard(
    icon: Icons.shopping_bag_outlined,
    title: 'Your bag is waiting',
    description: 'Explore the collection and add a piece you love.',
    buttonLabel: 'CONTINUE SHOPPING',
    onPressed: () {
      final cubit = context.read<HomeCubit>();
      Navigator.of(context).maybePop();
      cubit.selectTab(0);
    },
  );

  Widget _errorState(String error) => _infoCard(
    icon: Icons.cloud_off_outlined,
    title: 'Could not load your cart',
    description: error,
    buttonLabel: 'TRY AGAIN',
    onPressed: () => context.read<HomeCubit>().loadCart(),
  );

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) => Container(
    margin: EdgeInsets.only(top: 20.h),
    padding: EdgeInsets.all(22.w),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F0ED),
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Column(
      children: [
        Container(
          width: 72.w,
          height: 72.w,
          decoration: const BoxDecoration(
            color: Color(0xFFE9DFD4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32.sp, color: _gold),
        ),
        SizedBox(height: 16.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 7.h),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12.sp, height: 1.4),
        ),
        SizedBox(height: 17.h),
        FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(backgroundColor: _ink),
          child: Text(buttonLabel),
        ),
      ],
    ),
  );

  Widget _couponPanel(HomeState state) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: _boxDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: _gold, size: 20),
            SizedBox(width: 8.w),
            Text(
              'PROMO CODE',
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            if (state.appliedCoupon != null)
              TextButton(
                onPressed: () {
                  context.read<HomeCubit>().clearCartCoupon();
                  _couponController.clear();
                },
                child: const Text('REMOVE'),
              ),
          ],
        ),
        SizedBox(height: 7.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                enabled: state.appliedCoupon == null && !state.isCouponLoading,
                decoration: InputDecoration(
                  hintText: state.appliedCoupon ?? 'Enter code',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFFAF9F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            OutlinedButton(
              onPressed: state.appliedCoupon != null || state.isCouponLoading
                  ? null
                  : _applyCoupon,
              child: state.isCouponLoading
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(state.appliedCoupon == null ? 'APPLY' : 'APPLIED'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summary(HomeState state) => Container(
    padding: EdgeInsets.all(16.w),
    decoration: _boxDecoration(),
    child: Column(
      children: [
        _priceRow('Subtotal', state.couponOriginalTotal ?? state.cartSubtotal),
        if ((state.couponDiscountAmount ?? 0) > 0) ...[
          SizedBox(height: 9.h),
          Row(
            children: [
              const Expanded(child: Text('Discount')),
              Text(
                '− ${_money(state.couponDiscountAmount!)}',
                style: const TextStyle(color: Color(0xFF427052)),
              ),
            ],
          ),
        ],
        SizedBox(height: 9.h),
        _priceRow('Delivery', 0, valueText: 'Calculated at checkout'),
        Divider(height: 22.h, color: const Color(0xFFE8E3DE)),
        _priceRow('Total', state.cartTotal, bold: true),
      ],
    ),
  );

  Widget _priceRow(
    String label,
    double amount, {
    bool bold = false,
    String? valueText,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14.sp : 12.sp,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        valueText ?? _money(amount),
        style: TextStyle(
          fontSize: bold ? 15.sp : 12.sp,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _checkoutBar(HomeState state) => Container(
    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 14.h),
    decoration: BoxDecoration(
      color: const Color(0xFFFAF9F7),
      border: Border(
        top: BorderSide(color: Colors.black.withValues(alpha: .07)),
      ),
    ),
    child: SizedBox(
      width: double.infinity,
      height: 50.h,
      child: FilledButton.icon(
        onPressed: _checkingOut ? null : _checkout,
        style: FilledButton.styleFrom(
          backgroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9.r),
          ),
        ),
        icon: _checkingOut
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.lock_outline),
        label: Text(
          _checkingOut
              ? 'PREPARING CHECKOUT'
              : 'CHECKOUT · ${_money(state.cartTotal)}',
        ),
      ),
    ),
  );

  Future<void> _confirmRemove(BuildContext context, CartItem item) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove “${item.name}” from your bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KEEP'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (remove != true || !context.mounted) return;
    await _runCartAction(
      context,
      () => context.read<HomeCubit>().removeCartItem(item),
    );
  }

  Future<void> _runCartAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      _message(_api.errorMessage(error));
    }
  }

  static const _gold = Color(0xFF7B5D36);
  static const _ink = Color(0xFF171719);
  static const _muted = Color(0xFF77716C);

  static String _money(num amount) => '\$${amount.toStringAsFixed(2)}';

  static BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13.r),
  );
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.busy,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final bool busy;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: busy ? .55 : 1,
    child: Container(
      margin: EdgeInsets.only(bottom: 11.h),
      padding: EdgeInsets.all(11.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9.r),
            child: SizedBox(
              width: 82.w,
              height: 98.h,
              child: item.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFF1ECE5),
                      child: Icon(Icons.shopping_bag_outlined, color: _gold),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF1ECE5),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: _gold,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : onRemove,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 17.sp, color: _muted),
                    ),
                  ],
                ),
                if (item.discountPercentage > 0) ...[
                  SizedBox(height: 3.h),
                  Text(
                    '${item.discountPercentage.toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ],
                SizedBox(height: 7.h),
                Text(
                  _money(item.unitPrice),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _quantityButton(Icons.remove, busy ? null : onDecrement),
                    SizedBox(width: 10.w),
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _quantityButton(Icons.add, busy ? null : onIncrement),
                    const Spacer(),
                    Text(
                      _money(item.totalPrice),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (item.stock > 0 && item.quantity >= item.stock) ...[
                  SizedBox(height: 5.h),
                  Text(
                    'Maximum available quantity',
                    style: TextStyle(color: _muted, fontSize: 9.sp),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _quantityButton(IconData icon, VoidCallback? onPressed) => Container(
    width: 26.w,
    height: 26.w,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE6E1DC)),
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 14.sp),
    ),
  );

  static const _gold = Color(0xFF7B5D36);
  static const _muted = Color(0xFF77716C);
  static String _money(num amount) => '\$${amount.toStringAsFixed(2)}';
}

class _CartShimmer extends StatelessWidget {
  const _CartShimmer();

  @override
  Widget build(BuildContext context) => ShimmerLoading(
    child: Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 122.h,
          margin: EdgeInsets.only(bottom: 11.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13.r),
          ),
        ),
      ),
    ),
  );
}
