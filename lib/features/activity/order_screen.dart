import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';

class OrderScreen extends StatefulWidget {
  final Business business;
  const OrderScreen({super.key, required this.business});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Product> products = [];
  Map<int, int> cart = {};
  bool loading = true;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final pincodeCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String deliveryMethod = 'delivery';
  String? deliveryTimeSlot;
  late final String _clientReference;
  bool submitting = false;
  bool _checkingPincode = false;
  bool _checkingLocation = false;
  bool _notifyingInterest = false;
  Map<String, dynamic>? _pincodeResult;
  double _distanceKm = 0;
  double? _customerLatitude;
  double? _customerLongitude;
  StateSetter? _cartSheetState;

  static const List<String> timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-13:00',
    '13:00-14:00',
    '14:00-15:00',
    '15:00-16:00',
    '16:00-17:00',
    '17:00-18:00',
    '18:00-19:00',
    '19:00-20:00',
    '20:00-21:00',
  ];

  void _updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
    _cartSheetState?.call(() {});
  }

  @override
  void initState() {
    super.initState();
    _clientReference =
        'app-${widget.business.id}-${DateTime.now().microsecondsSinceEpoch}';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final res = await api.get(
        '/products',
        queryParams: {
          'business_id': widget.business.id.toString(),
          'per_page': '100',
        },
      );
      if (!mounted) return;
      final rawProducts = res['products'];
      final productData = rawProducts is Map<String, dynamic>
          ? rawProducts['data']
          : rawProducts;
      final list =
          (productData as List?)?.map((p) => Product.fromJson(p)).toList() ??
          [];
      _updateState(() {
        products = list;
        loading = false;
      });
    } catch (e) {
      if (mounted) _updateState(() => loading = false);
    }
  }

  int get _cartCount => cart.values.fold(0, (a, b) => a + b);
  double get _cartTotal {
    double total = 0;
    cart.forEach((id, qty) {
      final p = products.firstWhere(
        (x) => x.id == id,
        orElse: () => Product(id: id, name: '', slug: '', price: 0),
      );
      total += (p.price ?? 0) * qty;
    });
    return total;
  }

  double get _deliveryFee {
    if (deliveryMethod != 'delivery') return 0;
    if (_pincodeAvailable) {
      return (_pincodeResult!['delivery_fee'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  bool get _pincodeAvailable => _pincodeResult?['deliverable'] == true;

  Future<void> _checkPincode() async {
    final pincode = pincodeCtrl.text.trim();
    if (pincode.isEmpty) return;
    _updateState(() => _checkingPincode = true);
    try {
      final res = await api.get(
        '/delivery-zones/check-eligibility',
        queryParams: {
          'business_id': widget.business.id.toString(),
          'pincode': pincode,
          'subtotal': _cartTotal.toString(),
        },
      );
      if (mounted) _updateState(() => _pincodeResult = res);
    } catch (e) {
      if (mounted) {
        _updateState(
          () => _pincodeResult = {
            'available': false,
            'deliverable': false,
            'message': 'Could not verify pincode',
          },
        );
      }
    } finally {
      if (mounted) _updateState(() => _checkingPincode = false);
    }
  }

  Future<void> _checkLocation() async {
    _updateState(() => _checkingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Enter pincode instead.',
                ),
              ),
            );
          }
          _updateState(() => _checkingLocation = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final params = <String, String>{
        'business_id': widget.business.id.toString(),
        'latitude': pos.latitude.toString(),
        'longitude': pos.longitude.toString(),
        'subtotal': _cartTotal.toString(),
      };
      if (pincodeCtrl.text.trim().isNotEmpty) {
        params['pincode'] = pincodeCtrl.text.trim();
      }

      final res = await api.get(
        '/delivery-zones/check-eligibility',
        queryParams: params,
      );
      if (mounted) {
        _updateState(() {
          _customerLatitude = pos.latitude;
          _customerLongitude = pos.longitude;
          _pincodeResult = res;
          if (res['distance_km'] != null) {
            _distanceKm = (res['distance_km'] as num).toDouble();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location error: ${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) _updateState(() => _checkingLocation = false);
    }
  }

  Future<void> _notifyInterest() async {
    final pincode = pincodeCtrl.text.trim();
    if (pincode.isEmpty) return;
    _updateState(() => _notifyingInterest = true);
    try {
      await api.post(
        '/area-interest',
        body: {
          'pincode': pincode,
          'phone': phoneCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Thanks! We'll notify you when delivery is available in your area.",
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save interest. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) _updateState(() => _notifyingInterest = false);
    }
  }

  Future<void> _submitOrder() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    if (deliveryMethod == 'delivery') {
      if (addressCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a delivery address')),
        );
        return;
      }
      if (pincodeCtrl.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 6-digit pincode')),
        );
        return;
      }
      if (!_pincodeAvailable) {
        await _checkPincode();
        if (!mounted || !_pincodeAvailable) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _pincodeResult?['message']?.toString() ??
                      'Please verify delivery availability first',
                ),
              ),
            );
          }
          return;
        }
      }
    }

    _updateState(() => submitting = true);
    try {
      final items = cart.entries
          .map((e) => {'product_id': e.key, 'quantity': e.value})
          .toList();
      final res = await api.post(
        '/businesses/${widget.business.slug}/orders',
        body: {
          'items': items,
          'customer_name': nameCtrl.text.trim(),
          'customer_phone': phoneCtrl.text.trim(),
          'customer_email': emailCtrl.text.trim().isEmpty
              ? null
              : emailCtrl.text.trim(),
          'delivery_address': addressCtrl.text.trim().isEmpty
              ? null
              : addressCtrl.text.trim(),
          'delivery_method': deliveryMethod,
          'delivery_time_slot': deliveryTimeSlot,
          'pincode': pincodeCtrl.text.trim().isEmpty
              ? null
              : pincodeCtrl.text.trim(),
          'latitude': deliveryMethod == 'delivery' ? _customerLatitude : null,
          'longitude': deliveryMethod == 'delivery' ? _customerLongitude : null,
          'client_reference': _clientReference,
          'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      final duplicate = res['duplicate'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate
                ? 'This order request was already sent.'
                : 'Order request sent. Pay the business directly by cash/COD.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _updateState(() => submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    pincodeCtrl.dispose();
    addressCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Order from ${widget.business.name}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_cartCount > 0)
            Center(
              child: GestureDetector(
                onTap: () => _showCartBottomSheet(),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_cartCount  ₹${_cartTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : products.isEmpty
          ? const Center(child: Text('No products available'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildProductSections(
                  products.where((p) => p.isInStock).toList(),
                ),
                if (products.any((p) => !p.isInStock)) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildProductSections(
                    products.where((p) => !p.isInStock).toList(),
                    disabled: true,
                  ),
                ],
              ],
            ),
    );
  }

  List<Widget> _buildProductSections(
    List<Product> items, {
    bool disabled = false,
  }) {
    final sections = <String, List<Product>>{};
    for (final product in items) {
      sections
          .putIfAbsent(product.menuSection ?? 'Menu', () => [])
          .add(product);
    }

    return [
      for (final entry in sections.entries) ...[
        if (sections.length > 1 || entry.key != 'Menu')
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ...entry.value.map((p) => _buildProductCard(p, disabled: disabled)),
      ],
    ];
  }

  Widget _buildProductCard(Product p, {bool disabled = false}) {
    final qty = cart[p.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: disabled ? Colors.grey[400] : AppTheme.textPrimary,
                  ),
                ),
                if (p.description != null && p.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      p.description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(
                        '₹${p.price?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: disabled ? Colors.grey[400] : AppTheme.primary,
                        ),
                      ),
                      if (p.foodType != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          p.foodType == 'non_veg'
                              ? '🔴 Non-veg'
                              : '🟢 ${p.foodType == 'veg' ? 'Veg' : p.foodType}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (p.preparationMinutes != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${p.preparationMinutes} min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (disabled && p.availabilityMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      p.availabilityMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (disabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Unavailable',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            )
          else if (qty > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQtyBtn(Icons.remove, () {
                  _updateState(() {
                    if (qty > 1) {
                      cart[p.id] = qty - 1;
                    } else {
                      cart.remove(p.id);
                    }
                    _pincodeResult = null;
                  });
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                _buildQtyBtn(
                  Icons.add,
                  p.stock == null || qty < p.stock!
                      ? () => _updateState(() {
                          cart[p.id] = qty + 1;
                          _pincodeResult = null;
                        })
                      : () {},
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _updateState(() {
                cart[p.id] = 1;
                _pincodeResult = null;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          _cartSheetState = setSheetState;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _updateState(() {
                            cart.clear();
                            _pincodeResult = null;
                          });
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Cart Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: cart.entries.map((e) {
                      final p = products.firstWhere((x) => x.id == e.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '₹${p.price?.toStringAsFixed(0) ?? '0'} x ${e.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${((p.price ?? 0) * e.value).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                // Subtotal
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        '₹${_cartTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delivery Fee
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Delivery Fee',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (deliveryMethod == 'pickup')
                            Text(
                              ' (pickup)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.success,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        deliveryMethod == 'delivery'
                            ? '₹${_deliveryFee.toStringAsFixed(0)}'
                            : '₹0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: deliveryMethod == 'delivery'
                              ? AppTheme.textPrimary
                              : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Offline payment mode
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Flexible(
                        child: Text(
                          'Cash/COD directly to business',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 20, endIndent: 20),
                // Total
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${(_cartTotal + _deliveryFee).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Customer Details Form
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      const Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Delivery Method Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Method: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            _methodChip('Delivery', 'delivery'),
                            const SizedBox(width: 6),
                            _methodChip('Pickup', 'pickup'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (deliveryMethod == 'delivery') ...[
                        // Pincode input
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_post_office_outlined,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: pincodeCtrl,
                                  onChanged: (_) => _updateState(() {
                                    _pincodeResult = null;
                                    _distanceKm = 0;
                                  }),
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter pincode',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              if (_checkingPincode)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: _checkPincode,
                                  child: const Text(
                                    'Check',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Use GPS location button
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _checkingLocation
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _checkLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text(
                                    'Use my location for delivery check',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: BorderSide(
                                      color: AppTheme.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                        ),
                        // Pincode/eligibility result
                        if (_pincodeResult != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _pincodeAvailable
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _pincodeAvailable
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _pincodeAvailable
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 18,
                                      color: _pincodeAvailable
                                          ? AppTheme.primary
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pincodeAvailable
                                                ? 'Delivery available — ₹${_deliveryFee.toStringAsFixed(0)} fee'
                                                : '${_pincodeResult!['message'] ?? 'Delivery not available to this pincode'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _pincodeAvailable
                                                  ? AppTheme.primary
                                                  : Colors.red,
                                            ),
                                          ),
                                          if (_distanceKm > 0)
                                            Text(
                                              'Distance: ${_distanceKm.toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_pincodeResult!['pincode_info'] !=
                                    null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_pincodeResult!['pincode_info']['locality'] ?? ''}, ${_pincodeResult!['pincode_info']['district'] ?? ''}, ${_pincodeResult!['pincode_info']['state'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                if (!_pincodeAvailable &&
                                    _pincodeResult?['message']?.contains(
                                          'soon',
                                        ) ==
                                        true) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: _notifyingInterest
                                        ? const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : OutlinedButton.icon(
                                            onPressed: _notifyInterest,
                                            icon: const Icon(
                                              Icons.notifications_outlined,
                                              size: 14,
                                            ),
                                            label: const Text(
                                              'Notify me when available',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.primary,
                                              side: BorderSide(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.3),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (widget
                            .business
                            .deliveryZones
                            .isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget
                                          .business
                                          .deliveryZones
                                          .first
                                          .areaName ??
                                      'Area available',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₹${widget.business.deliveryZones.first.deliveryFee.toStringAsFixed(0)} fee',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        _buildField(
                          addressCtrl,
                          'Delivery Address',
                          Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Time Slot
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Preferred Time Slot',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: timeSlots.map((slot) {
                                final selected = deliveryTimeSlot == slot;
                                return GestureDetector(
                                  onTap: () => _updateState(
                                    () => deliveryTimeSlot = selected
                                        ? null
                                        : slot,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppTheme.primary
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selected
                                            ? AppTheme.primary
                                            : AppTheme.border,
                                      ),
                                    ),
                                    child: Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        nameCtrl,
                        'Full Name *',
                        Icons.person_outline,
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        phoneCtrl,
                        'Phone Number *',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        emailCtrl,
                        'Email (optional)',
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        notesCtrl,
                        'Notes (optional)',
                        Icons.notes_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _submitOrder();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Place COD Order - ₹${(_cartTotal + _deliveryFee).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => _cartSheetState = null);
  }

  Widget _methodChip(String label, String value) {
    final selected = deliveryMethod == value;
    return GestureDetector(
      onTap: () => _updateState(() {
        deliveryMethod = value;
        _pincodeResult = null;
        _distanceKm = 0;
        if (value == 'pickup') {
          _customerLatitude = null;
          _customerLongitude = null;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
