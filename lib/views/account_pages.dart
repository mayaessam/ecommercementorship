import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const Color _auraGold = Color(0xFF7B5D36);
const Color _auraBackground = Color(0xFFFAF9F7);
const Color _auraInk = Color(0xFF171719);
const Color _auraMuted = Color(0xFF77716C);
const Color _auraBeige = Color(0xFFF4F1EF);

class _AuraPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _AuraPage({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _auraBackground,
      appBar: AppBar(
        backgroundColor: _auraBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _auraInk,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: action == null ? null : [action!],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: TextStyle(
                      color: _auraGold,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _sectionTitle(String text) {
  return Padding(
    padding: EdgeInsets.only(top: 20.h, bottom: 12.h),
    child: Text(
      text,
      style: TextStyle(
        color: _auraInk,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _emptyState(IconData icon, String title, String message) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
    ),
    child: Column(
      children: [
        Icon(icon, size: 38.sp, color: _auraGold),
        SizedBox(height: 12.h),
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: _auraMuted),
        ),
      ],
    ),
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

// ============================================================
// 1. ORDER HISTORY & TRACKING
// ============================================================

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'AU-2048',
      'date': '24 Oct 2026',
      'total': 185.00,
      'status': 'In Transit',
      'items': 'Signature perfume · 1 item',
      'step': 2,
    },
    {
      'id': 'AU-1982',
      'date': '12 Oct 2026',
      'total': 320.00,
      'status': 'Delivered',
      'items': 'Luxury skincare set · 2 items',
      'step': 3,
    },
    {
      'id': 'AU-1760',
      'date': '28 Sep 2026',
      'total': 95.00,
      'status': 'Delivered',
      'items': 'Silk accessory · 1 item',
      'step': 3,
    },
    {
      'id': 'AU-1621',
      'date': '15 Sep 2026',
      'total': 240.00,
      'status': 'Cancelled',
      'items': 'Beauty collection · 3 items',
      'step': 0,
    },
  ];

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _auraBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (sheetContext) {
        final int step = order['step'] as int;
        final String status = order['status'] as String;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(22.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D3CD),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'ORDER DETAILS',
                    style: TextStyle(
                      color: _auraGold,
                      fontSize: 10.sp,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Order #${order['id']}',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${order['date']} · ${order['items']}',
                    style: TextStyle(color: _auraMuted, fontSize: 12.sp),
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shipment tracking',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        _trackingStep(
                          'Order confirmed',
                          'Your order has been received.',
                          step >= 1,
                          isLast: false,
                        ),
                        _trackingStep(
                          'Preparing your order',
                          'Your items are being prepared.',
                          step >= 2,
                          isLast: false,
                        ),
                        _trackingStep(
                          'Out for delivery',
                          'Your package is on its way.',
                          step >= 3,
                          isLast: false,
                        ),
                        _trackingStep(
                          'Delivered',
                          'Your order has arrived.',
                          status == 'Delivered',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order total',
                        style: TextStyle(fontSize: 14.sp, color: _auraMuted),
                      ),
                      Text(
                        '\$${(order['total'] as num).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('CLOSE'),
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

  @override
  Widget build(BuildContext context) {
    return _AuraPage(
      title: 'My Orders',
      subtitle: 'Your shopping journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ORDER HISTORY (${_orders.length})'),
          if (_orders.isEmpty)
            _emptyState(
              Icons.shopping_bag_outlined,
              'No orders yet',
              'Your future AURA purchases will appear here.',
            )
          else
            ..._orders.map((order) {
              final String status = order['status'] as String;
              final Color statusColor = status == 'Delivered'
                  ? const Color(0xFF477453)
                  : status == 'Cancelled'
                  ? Colors.red.shade700
                  : _auraGold;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${order['id']}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      order['items'] as String,
                      style: TextStyle(color: _auraMuted, fontSize: 12.sp),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      order['date'] as String,
                      style: TextStyle(color: _auraMuted, fontSize: 11.sp),
                    ),
                    Divider(height: 24.h, color: _auraBeige),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${(order['total'] as num).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showOrderDetails(order),
                          child: const Text(
                            'VIEW DETAILS',
                            style: TextStyle(color: _auraGold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

Widget _trackingStep(
  String title,
  String description,
  bool completed, {
  required bool isLast,
}) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 28.w,
          child: Column(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.circle_outlined,
                color: completed ? _auraGold : const Color(0xFFD5CEC7),
                size: 19.sp,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: completed ? _auraGold : const Color(0xFFE4DED8),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h, left: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: completed ? _auraInk : _auraMuted,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: _auraMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// 2. SHIPPING ADDRESSES
// ============================================================

class ShippingAddressesScreen extends StatefulWidget {
  const ShippingAddressesScreen({super.key});

  @override
  State<ShippingAddressesScreen> createState() =>
      _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState extends State<ShippingAddressesScreen> {
  final List<Map<String, String>> _addresses = [
    {
      'name': 'Elena Rostova',
      'label': 'Home',
      'address': '12 Milan Central, Milan',
      'phone': '+39 000 000 0000',
    },
    {
      'name': 'Elena Rostova',
      'label': 'Work',
      'address': 'Fashion District, Milan',
      'phone': '+39 000 000 0000',
    },
  ];

  int _defaultIndex = 0;

  Future<void> _editAddress({int? index}) async {
    final existing = index == null ? null : _addresses[index];
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final labelController = TextEditingController(
      text: existing?['label'] ?? '',
    );
    final addressController = TextEditingController(
      text: existing?['address'] ?? '',
    );
    final phoneController = TextEditingController(
      text: existing?['phone'] ?? '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _auraBackground,
        title: Text(index == null ? 'Add address' : 'Edit address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _formField(nameController, 'Full name'),
              _formField(labelController, 'Label (Home, Work...)'),
              _formField(addressController, 'Street and city'),
              _formField(phoneController, 'Phone number'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _auraGold),
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  labelController.text.trim().isEmpty ||
                  addressController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                _showMessage(dialogContext, 'Please fill in every field.');
                return;
              }

              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'label': labelController.text.trim(),
                'address': addressController.text.trim(),
                'phone': phoneController.text.trim(),
              });
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    nameController.dispose();
    labelController.dispose();
    addressController.dispose();
    phoneController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      if (index == null) {
        _addresses.add(result);
      } else {
        _addresses[index] = result;
      }
    });
  }

  void _deleteAddress(int index) {
    if (_addresses.length == 1) {
      _showMessage(context, 'Keep at least one saved address.');
      return;
    }

    setState(() {
      _addresses.removeAt(index);
      if (_defaultIndex == index) {
        _defaultIndex = 0;
      } else if (_defaultIndex > index) {
        _defaultIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AuraPage(
      title: 'Shipping Addresses',
      subtitle: 'Where we deliver',
      action: IconButton(
        onPressed: () => _editAddress(),
        icon: const Icon(Icons.add, color: _auraGold),
        tooltip: 'Add address',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SAVED ADDRESSES'),
          if (_addresses.isEmpty)
            _emptyState(
              Icons.location_on_outlined,
              'No saved addresses',
              'Add an address for your next order.',
            )
          else
            ...List.generate(_addresses.length, (index) {
              final address = _addresses[index];
              final isDefault = index == _defaultIndex;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDefault ? _auraGold : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: _auraGold,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            address['label']!,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isDefault)
                          const Icon(
                            Icons.check_circle,
                            color: _auraGold,
                            size: 19,
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      address['name']!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      address['address']!,
                      style: TextStyle(fontSize: 12.sp, color: _auraMuted),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      address['phone']!,
                      style: TextStyle(fontSize: 12.sp, color: _auraMuted),
                    ),
                    Divider(height: 24.h, color: _auraBeige),
                    Wrap(
                      spacing: 4.w,
                      children: [
                        TextButton(
                          onPressed: () => _editAddress(index: index),
                          child: const Text(
                            'EDIT',
                            style: TextStyle(color: _auraGold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _deleteAddress(index),
                          child: Text(
                            'DELETE',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                        if (!isDefault)
                          TextButton(
                            onPressed: () {
                              setState(() => _defaultIndex = index);
                              _showMessage(context, 'Default address updated.');
                            },
                            child: const Text(
                              'SET DEFAULT',
                              style: TextStyle(color: _auraGold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _editAddress(),
              icon: const Icon(Icons.add, color: _auraGold),
              label: const Text(
                'ADD NEW ADDRESS',
                style: TextStyle(color: _auraGold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _formField(TextEditingController controller, String label) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

// ============================================================
// 3. PAYMENT METHODS
// ============================================================

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, String>> _methods = [
    {'brand': 'Mastercard', 'last4': '4022', 'expiry': '08/28'},
  ];

  int _defaultIndex = 0;

  Future<void> _addMethod() async {
    final brandController = TextEditingController(text: 'Visa');
    final last4Controller = TextEditingController();
    final expiryController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _auraBackground,
        title: const Text('Add payment method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: 'Visa',
              decoration: const InputDecoration(labelText: 'Card type'),
              items: const [
                DropdownMenuItem(value: 'Visa', child: Text('Visa')),
                DropdownMenuItem(
                  value: 'Mastercard',
                  child: Text('Mastercard'),
                ),
                DropdownMenuItem(
                  value: 'American Express',
                  child: Text('American Express'),
                ),
              ],
              onChanged: (value) {
                if (value != null) brandController.text = value;
              },
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: last4Controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Last 4 digits only',
                counterText: '',
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry (MM/YY)',
                hintText: '08/28',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Demo only. Never enter a full card number or security code.',
              style: TextStyle(fontSize: 11.sp, color: _auraMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _auraGold),
            onPressed: () {
              final last4 = last4Controller.text.trim();
              final expiry = expiryController.text.trim();

              if (!RegExp(r'^\d{4}$').hasMatch(last4) ||
                  !RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
                _showMessage(
                  dialogContext,
                  'Enter four digits and expiry as MM/YY.',
                );
                return;
              }

              Navigator.pop(dialogContext, {
                'brand': brandController.text,
                'last4': last4,
                'expiry': expiry,
              });
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    brandController.dispose();
    last4Controller.dispose();
    expiryController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      _methods.add(result);
      _defaultIndex = _methods.length - 1;
    });

    _showMessage(context, 'Payment method added to this demo.');
  }

  void _deleteMethod(int index) {
    setState(() {
      _methods.removeAt(index);
      if (_methods.isEmpty) {
        _defaultIndex = -1;
      } else if (_defaultIndex == index) {
        _defaultIndex = 0;
      } else if (_defaultIndex > index) {
        _defaultIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AuraPage(
      title: 'Payment Methods',
      subtitle: 'Your saved payment options',
      action: IconButton(
        onPressed: _addMethod,
        icon: const Icon(Icons.add, color: _auraGold),
        tooltip: 'Add payment method',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('SAVED METHODS'),
          if (_methods.isEmpty)
            _emptyState(
              Icons.credit_card_outlined,
              'No payment methods',
              'Add a payment method for easier checkout.',
            )
          else
            ...List.generate(_methods.length, (index) {
              final method = _methods[index];
              final isDefault = index == _defaultIndex;

              return Container(
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF292623), Color(0xFF5A4A3A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          color: Colors.white,
                          size: 26,
                        ),
                        const Spacer(),
                        Text(
                          method['brand']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                    Text(
                      '••••  ••••  ••••  ${method['last4']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.sp,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'EXPIRES ${method['expiry']}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.sp,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2D5C5),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: _auraInk,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        if (!isDefault)
                          TextButton(
                            onPressed: () {
                              setState(() => _defaultIndex = index);
                              _showMessage(
                                context,
                                'Default payment method updated.',
                              );
                            },
                            child: const Text(
                              'SET AS DEFAULT',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _confirmDelete(index),
                          tooltip: 'Remove method',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addMethod,
              icon: const Icon(Icons.add, color: _auraGold),
              label: const Text(
                'ADD PAYMENT METHOD',
                style: TextStyle(color: _auraGold),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, color: _auraGold, size: 19),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'This is a UI demo. Connect a PCI-compliant payment provider '
                  'to securely save payment methods for real purchases.',
                  style: TextStyle(color: _auraMuted, fontSize: 11.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove payment method?'),
        content: const Text('This demo will remove the selected method.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('REMOVE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _deleteMethod(index);
    }
  }
}

// ============================================================
// 4. NOTIFICATIONS & NEWSLETTER
// ============================================================

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Your order is on its way',
      'message': 'Order AU-2048 is currently in transit.',
      'time': '2 hours ago',
      'icon': Icons.local_shipping_outlined,
      'read': false,
    },
    {
      'title': 'VIP early access',
      'message': 'Discover selected pieces before everyone else.',
      'time': 'Yesterday',
      'icon': Icons.star_outline,
      'read': false,
    },
    {
      'title': 'Welcome to AURA',
      'message': 'Thank you for joining our community.',
      'time': '3 days ago',
      'icon': Icons.favorite_border,
      'read': true,
    },
  ];

  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newsletter = true;
  bool _vipAccess = true;

  int get _unreadCount =>
      _notifications.where((item) => item['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return _AuraPage(
      title: 'Notifications',
      subtitle: 'Stay in the know',
      action: TextButton(
        onPressed: _unreadCount == 0
            ? null
            : () {
                setState(() {
                  for (final item in _notifications) {
                    item['read'] = true;
                  }
                });
              },
        child: Text(
          'READ ALL',
          style: TextStyle(
            color: _unreadCount == 0 ? _auraMuted : _auraGold,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionTitle('RECENT ACTIVITY')),
              if (_unreadCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _auraBeige,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_unreadCount unread',
                    style: TextStyle(
                      color: _auraGold,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (_notifications.isEmpty)
            _emptyState(
              Icons.notifications_none_outlined,
              'You are all caught up',
              'New updates will appear here.',
            )
          else
            ...List.generate(_notifications.length, (index) {
              final item = _notifications[index];
              final bool unread = item['read'] == false;

              return InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  setState(() => item['read'] = true);
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(item['title'] as String),
                      content: Text(item['message'] as String),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('CLOSE'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: unread ? const Color(0xFFF3EEE8) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: _auraGold,
                          size: 21.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: unread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              item['message'] as String,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _auraMuted,
                              ),
                            ),
                            SizedBox(height: 7.h),
                            Text(
                              item['time'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: _auraMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          margin: EdgeInsets.only(top: 5.h, left: 5.w),
                          decoration: const BoxDecoration(
                            color: _auraGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          _sectionTitle('NOTIFICATION PREFERENCES'),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: [
                _preferenceTile(
                  'Order updates',
                  'Shipping and delivery alerts',
                  _orderUpdates,
                  (value) => setState(() => _orderUpdates = value),
                ),
                _preferenceTile(
                  'Promotions',
                  'Offers and seasonal collections',
                  _promotions,
                  (value) => setState(() => _promotions = value),
                ),
                _preferenceTile(
                  'Newsletter',
                  'Curated updates from AURA',
                  _newsletter,
                  (value) => setState(() => _newsletter = value),
                ),
                _preferenceTile(
                  'VIP early access',
                  'Exclusive previews and pre-orders',
                  _vipAccess,
                  (value) => setState(() => _vipAccess = value),
                  isLast: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Preferences are stored in memory for this demo and reset '
            'when the app is restarted.',
            style: TextStyle(color: _auraMuted, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}

Widget _preferenceTile(
  String title,
  String subtitle,
  bool value,
  ValueChanged<bool> onChanged, {
  bool isLast = false,
}) {
  return Column(
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: _auraGold,
        title: Text(
          title,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10.sp, color: _auraMuted),
        ),
        value: value,
        onChanged: onChanged,
      ),
      if (!isLast) const Divider(height: 1, color: _auraBeige),
    ],
  );
}
