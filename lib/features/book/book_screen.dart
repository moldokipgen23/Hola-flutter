import 'package:flutter/material.dart';
import '../../design_system/components/hero_card.dart';
import '../../design_system/components/category_grid.dart';
import '../../design_system/components/eiho_bottom_sheet.dart';
import '../../design_system/components/toast.dart';
import '../../models/models.dart';
import '../../models/launch_config.dart';
import '../../models/booking.dart' as booking_models;
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../services/launch_control_service.dart';
import '../activity/my_bookings_screen.dart';

class BookScreen extends StatefulWidget {
  final LaunchConfig? launchConfig;
  const BookScreen({super.key, this.launchConfig});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isLoggedIn = false;
  List<Business> _businesses = [];
  List<Category> _categories = [];
  String? _selectedCategory;

  LaunchConfig get _launchConfig =>
      widget.launchConfig ?? LaunchControlService.instance.config;

  static const _fallbackCategories = [
    CategoryItem(emoji: '🏨', label: 'Hotels'),
    CategoryItem(emoji: '💇', label: 'Salon'),
    CategoryItem(emoji: '🩺', label: 'Doctors'),
    CategoryItem(emoji: '⚽', label: 'Turf'),
    CategoryItem(emoji: '🧪', label: 'Labs'),
    CategoryItem(emoji: '📷', label: 'Photography'),
    CategoryItem(emoji: '🏋️', label: 'Gym'),
    CategoryItem(emoji: '🎓', label: 'Classes'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final loggedIn = await AuthService.isLoggedIn();

      final results = await Future.wait([
        _launchConfig.experience('appointment')
            ? BusinessService.list(experience: 'appointment')
            : Future.value(<Business>[]),
        _launchConfig.experience('stay')
            ? BusinessService.list(experience: 'stay')
            : Future.value(<Business>[]),
        CategoryService.getCategories(),
      ]);

      final appointmentBiz = results[0] as List<Business>;
      final stayBiz = results[1] as List<Business>;
      final allCategories = results[2] as List<Category>;

      final bookable = <Business>{};
      for (final b in [...appointmentBiz, ...stayBiz]) {
        if (b.hasBookingsModule || b.isBookable == true) {
          bookable.add(b);
        }
      }

      final bookingCategories = allCategories
          .where((c) => c.isBooking || c.isBoth)
          .toList();

      if (mounted) {
        setState(() {
          _isLoggedIn = loggedIn;
          _businesses = bookable.toList();
          _categories = bookingCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load data. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                'Appointments, rooms and services',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (_isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              } else {
                ToastHelper.show(context, 'Login to view bookings');
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF087C7B),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF087C7B), Color(0xFF22A8A1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF087C7B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HeroCard(
            gradientColors: [Color(0xFF087C7B), Color(0xFF22A8A1)],
            kicker: 'BOOK LOCAL SERVICES',
            title: 'Find a trusted service today.',
            description:
                'Request appointments and reservations with clear confirmation.',
            ctaText: '',
            artEmoji: '✨',
          ),
          const SizedBox(height: 20),
          const Text(
            'What do you need?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 11),
          _buildCategoryGrid(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _buildServiceList(),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final List<CategoryItem> items;

    if (_categories.isNotEmpty) {
      items = _categories.map((cat) {
        final isActive = _selectedCategory == cat.slug;
        return CategoryItem(
          emoji: _categoryEmoji(cat.slug),
          label: isActive ? '${cat.name} ✓' : cat.name,
          onTap: () => _filterByCategory(cat),
        );
      }).toList();
    } else {
      items = _fallbackCategories.where((item) {
        if (item.label == 'Hotels') return _launchConfig.experience('stay');
        if (item.label == 'Turf') return _launchConfig.experience('turf');
        return _launchConfig.experience('appointment');
      }).toList();
    }

    return Column(
      children: [
        if (_selectedCategory != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filtered by: ${_categories.firstWhere((c) => c.slug == _selectedCategory).name}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF087C7B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close, size: 14, color: Color(0xFF087C7B)),
                  ],
                ),
              ),
            ),
          ),
        CategoryGrid(softColor: const Color(0xFFE7F8F6), categories: items),
      ],
    );
  }

  String _categoryEmoji(String slug) {
    switch (slug) {
      case 'hotels-lodges':
        return '🏨';
      case 'salon-beauty':
        return '💇';
      case 'doctors-clinics':
        return '🩺';
      case 'turf-sports':
        return '⚽';
      case 'gym-fitness':
        return '🏋️';
      case 'events-venues':
        return '🎉';
      case 'photography':
        return '📷';
      case 'education-classes':
        return '🎓';
      default:
        return '📌';
    }
  }

  void _filterByCategory(Category category) {
    setState(() {
      if (_selectedCategory == category.slug) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category.slug;
      }
    });
  }

  Widget _buildServiceList() {
    final displayed = _selectedCategory != null
        ? _businesses
              .where((b) => b.category?.slug == _selectedCategory)
              .toList()
        : _businesses;

    if (displayed.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _selectedCategory != null
                  ? 'No services in this category'
                  : 'No bookable services available right now',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: displayed.map((business) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildServiceItem(business),
        );
      }).toList(),
    );
  }

  Widget _buildServiceItem(Business business) {
    final firstService = business.topServices.isNotEmpty
        ? business.topServices.first
        : null;
    final serviceLabel = firstService != null
        ? '${firstService.name} · ₹${firstService.price.toStringAsFixed(0)}'
        : business.description ?? 'Book now';
    final ratingStr = business.averageRating > 0
        ? '★ ${business.averageRating.toStringAsFixed(1)}'
        : '';
    final distanceStr = business.distance != null ? '${business.distance}' : '';
    final priceStr = firstService != null
        ? '₹${firstService.price.toStringAsFixed(0)}'
        : '';
    final categoryEmoji = _categoryEmoji(business.category?.slug ?? '');

    return GestureDetector(
      onTap: () => _openBookingSheet(business),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Row(
          children: [
            Container(
              width: 67,
              height: 67,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F8F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  categoryEmoji,
                  style: const TextStyle(fontSize: 29),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (ratingStr.isNotEmpty)
                        Text(
                          ratingStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB66B00),
                          ),
                        ),
                      if (ratingStr.isNotEmpty) const SizedBox(width: 7),
                      if (distanceStr.isNotEmpty)
                        Text(
                          distanceStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF667085),
                          ),
                        ),
                      if (distanceStr.isNotEmpty) const SizedBox(width: 7),
                      if (business.locality != null)
                        Expanded(
                          child: Text(
                            business.locality!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF667085),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (priceStr.isNotEmpty)
              Text(
                priceStr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openBookingSheet(Business business) async {
    List<booking_models.Service> services = [];
    bool loadingServices = true;

    EihoBottomSheet.show(
      context,
      StatefulBuilder(
        builder: (context, setSheetState) {
          if (loadingServices) {
            BusinessService.services(business.slug).then((result) {
              if (mounted) {
                setSheetState(() {
                  services = result;
                  loadingServices = false;
                });
              }
            });
          }

          return _BookingSheetContent(
            business: business,
            services: services,
            isLoading: loadingServices,
          );
        },
      ),
    );
  }
}

class _BookingSheetContent extends StatefulWidget {
  final Business business;
  final List<booking_models.Service> services;
  final bool isLoading;

  const _BookingSheetContent({
    required this.business,
    required this.services,
    required this.isLoading,
  });

  @override
  State<_BookingSheetContent> createState() => _BookingSheetContentState();
}

class _BookingSheetContentState extends State<_BookingSheetContent> {
  booking_models.Service? _selectedService;
  String? _selectedDate;
  String? _selectedTime;
  List<TimeSlot> _slots = [];
  bool _loadingSlots = false;
  bool _submitting = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadSlots() async {
    if (_selectedService == null || _selectedDate == null) return;
    setState(() => _loadingSlots = true);
    final result = await BusinessService.slots(
      widget.business.slug,
      serviceId: _selectedService!.id,
      date: _selectedDate,
    );
    if (mounted) {
      setState(() {
        _slots = result;
        _loadingSlots = false;
        _selectedTime = null;
      });
    }
  }

  void _submit() async {
    if (_selectedService == null) {
      ToastHelper.show(context, 'Please select a service');
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ToastHelper.show(context, 'Please select a date and time');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ToastHelper.show(context, 'Please enter your name and phone');
      return;
    }

    setState(() => _submitting = true);

    final result = await BookingService.create(
      businessSlug: widget.business.slug,
      serviceId: _selectedService!.id,
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      bookingDate: _selectedDate!,
      startTime: _selectedTime,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (result.isNotEmpty) {
        Navigator.pop(context);
        ToastHelper.show(context, 'Booking request sent!');
      } else {
        ToastHelper.show(context, 'Failed to send booking. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SheetHeader(title: 'Book ${widget.business.name}'),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select service',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 11),
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF087C7B),
                strokeWidth: 2,
              ),
            ),
          )
        else if (widget.services.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: const Center(
              child: Text(
                'No services available',
                style: TextStyle(fontSize: 13, color: Color(0xFF667085)),
              ),
            ),
          )
        else
          ...widget.services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedService = service);
                  _loadSlots();
                },
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedService?.id == service.id
                          ? const Color(0xFF087C7B)
                          : const Color(0xFFE7EAF0),
                      width: _selectedService?.id == service.id ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selectedService?.id == service.id
                              ? const Color(0xFFD4EFED)
                              : const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            _selectedService?.id == service.id ? '✓' : '🔧',
                            style: TextStyle(
                              fontSize: 22,
                              color: _selectedService?.id == service.id
                                  ? const Color(0xFF087C7B)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service.duration} min',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Choose a date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 11),
        _buildDateRow(),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Choose a time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 11),
        _buildTimeSlots(),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 11),
        _buildDetailField('Name', _nameCtrl, 'Enter your name'),
        const SizedBox(height: 10),
        _buildDetailField('Phone', _phoneCtrl, 'Enter your phone number'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('ℹ️', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request confirmation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'You will be notified once confirmed.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _submitting ? null : _submit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _submitting
                    ? [Colors.grey[400]!, Colors.grey[300]!]
                    : const [Color(0xFF087C7B), Color(0xFF22A8A1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send booking request',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDateRow() {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final dateStr = _formatDate(date);
          final isSelected = _selectedDate == dateStr;
          final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          final monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = dateStr);
              _loadSlots();
            },
            child: Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF087C7B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF087C7B)
                      : const Color(0xFFE7EAF0),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[date.weekday % 7],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthNames[date.month - 1],
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedService == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'Select a service first',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ),
      );
    }

    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF087C7B),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No available slots for this date',
            style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots.map((slot) {
        final timeStr = slot.startTime;
        final isSelected = _selectedTime == timeStr;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = timeStr),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF087C7B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF087C7B)
                    : const Color(0xFFE7EAF0),
              ),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailField(
    String label,
    TextEditingController ctrl,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0B8C9)),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
