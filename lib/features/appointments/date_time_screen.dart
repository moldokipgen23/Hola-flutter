import 'package:flutter/material.dart';
import '../../design_system/tokens/design_tokens.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import 'booking_summary_screen.dart';

class DateTimeScreen extends StatefulWidget {
  final int businessId;
  final String businessSlug;
  final String? staffId;
  final String? serviceId;
  final List<Service> services;
  final String? staffName;

  const DateTimeScreen({
    super.key,
    required this.businessId,
    required this.businessSlug,
    this.staffId,
    this.serviceId,
    required this.services,
    this.staffName,
  });

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<Map<String, dynamic>> _timeSlots = [];
  bool _loadingSlots = false;
  Set<String> _availableDates = {};
  String? _slotsError;
  String? _selectedServiceId;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.serviceId;
    _loadAvailability();
    _loadTimeSlots();
  }

  Service? get _selectedService {
    if (_selectedServiceId == null) return null;
    try {
      return widget.services.firstWhere(
        (s) => s.id.toString() == _selectedServiceId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAvailability() async {
    try {
      final params = <String, String>{
        'business_id': widget.businessId.toString(),
      };
      if (_selectedServiceId != null) params['service_id'] = _selectedServiceId!;
      if (widget.staffId != null) params['staff_id'] = widget.staffId!;

      final res = await api.get(
        '/businesses/${widget.businessSlug}/availability',
        queryParams: params,
      );

      if (mounted) {
        setState(() {
          _availableDates = Set<String>.from(
            (res['available_dates'] as List? ?? []).map((d) => d.toString()),
          );
        });
      }
    } catch (_) {
      // Silently handle — show all dates as fallback
    }
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
    });

    try {
      final params = <String, String>{
        'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      };
      if (_selectedServiceId != null) params['service_id'] = _selectedServiceId!;
      if (widget.staffId != null) params['staff_id'] = widget.staffId!;

      final res = await api.get(
        '/businesses/${widget.businessSlug}/slots',
        queryParams: params,
      );

      if (mounted) {
        setState(() {
          _timeSlots = List<Map<String, dynamic>>.from(res['slots'] ?? []);
          _selectedTime = null;
          _loadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _slotsError = e.toString();
          _loadingSlots = false;
        });
      }
    }
  }

  bool get _canProceed => _selectedTime != null;

  void _proceedToSummary() {
    if (!_canProceed || _selectedTime == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          businessId: widget.businessId,
          businessSlug: widget.businessSlug,
          service: _selectedService,
          staffId: widget.staffId,
          staffName: widget.staffName,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book appointment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                _buildStepIndicator(1, 'Date & Time', true),
                Expanded(child: Container(height: 2, color: AppColors.line)),
                _buildStepIndicator(2, 'Review', false),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                if (widget.services.length > 1) ...[
                  _buildServiceChips(),
                  const SizedBox(height: 16),
                ],
                _buildCalendarSection(),
                const SizedBox(height: 16),
                _buildTimeSlotsSection(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.line,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.primary : AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.services.map((service) {
            final isSelected = _selectedServiceId == service.id.toString();
            return GestureDetector(
              onTap: () {
                setState(() => _selectedServiceId = service.id.toString());
                _loadAvailability();
                _loadTimeSlots();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Text(
                  service.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    final now = DateTime.now();
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141846).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                        );
                      });
                      _loadTimeSlots();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, size: 18, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                        );
                      });
                      _loadTimeSlots();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstDayOfWeek + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstDayOfWeek) return const SizedBox();
              final day = index - firstDayOfWeek + 1;
              final date = DateTime(_selectedDate.year, _selectedDate.month, day);
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
              final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isAvailable = _availableDates.isEmpty || _availableDates.contains(dateStr);

              return GestureDetector(
                onTap: isPast || !isAvailable
                    ? null
                    : () {
                        setState(() => _selectedDate = date);
                        _loadTimeSlots();
                      },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isPast || !isAvailable
                            ? Colors.grey[300]
                            : isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.gold
                                    : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141846).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABLE TIMES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.muted,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else if (_slotsError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load slots',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            )
          else if (_timeSlots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No slots available for this date',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final time = slot['start_time']?.toString() ?? '';
                final available = slot['available'] == true || slot['is_available'] == true;
                final isSelected = _selectedTime == time;
                final displayTime = _formatTime(time);

                return GestureDetector(
                  onTap: available
                      ? () => setState(() => _selectedTime = time)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : available
                              ? Colors.white
                              : AppColors.soft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : available
                                ? AppColors.line
                                : AppColors.line.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : available
                                ? AppColors.textPrimary
                                : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _canProceed ? _proceedToSummary : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _canProceed ? AppColors.gold : AppColors.line,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Continue to review',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _canProceed ? const Color(0xFF1a1421) : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final min = parts[1];
      if (hour == 0) return '12:$min AM';
      if (hour < 12) return '$hour:$min AM';
      if (hour == 12) return '12:$min PM';
      return '${hour - 12}:$min PM';
    } catch (_) {
      return time24;
    }
  }
}
