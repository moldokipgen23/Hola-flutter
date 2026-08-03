import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';

class BookingScreen extends StatefulWidget {
  final Business business;
  const BookingScreen({super.key, required this.business});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Service> services = [];
  Service? selectedService;
  DateTime selectedDate = DateTime.now();
  DateTime selectedCheckout = DateTime.now().add(const Duration(days: 1));
  TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final seatLabelsCtrl = TextEditingController();
  int partySize = 1;
  int reservationUnits = 1;
  bool loading = true;
  bool submitting = false;
  late final String _clientReference;

  List<TimeSlot> timeSlots = [];
  TimeSlot? selectedSlot;
  bool loadingSlots = false;

  @override
  void initState() {
    super.initState();
    _clientReference =
        'app-booking-${widget.business.id}-${DateTime.now().microsecondsSinceEpoch}';
    _loadServices();
  }

  String _formatTime(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mStr = m > 0 ? ':${m.toString().padLeft(2, '0')}' : '';
    return '$h12$mStr $period';
  }

  int _timeToMinutes(String time24) {
    final parts = time24.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String _timeOfDayLabel(String time24) {
    final mins = _timeToMinutes(time24);
    if (mins < 720) return 'Morning'; // before 12pm
    if (mins < 1020) return 'Afternoon'; // 12pm - 5pm (17:00 = 1020 min)
    return 'Evening';
  }

  Future<void> _loadServices() async {
    try {
      final res = await api.get('/businesses/${widget.business.slug}/services');
      if (!mounted) return;
      final list =
          (res['services'] as List?)
              ?.map((s) => Service.fromJson(s))
              .toList() ??
          [];
      setState(() {
        services = list;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        if (!selectedCheckout.isAfter(picked)) {
          selectedCheckout = picked.add(const Duration(days: 1));
        }
        selectedSlot = null;
      });
      _loadSlots();
    }
  }

  Future<void> _pickCheckout() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedCheckout,
      firstDate: selectedDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => selectedCheckout = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
          endTime = TimeOfDay(
            hour: picked.hour + (selectedService?.duration ?? 60) ~/ 60,
            minute: picked.minute + (selectedService?.duration ?? 60) % 60,
          );
        } else {
          endTime = picked;
        }
      });
    }
  }

  int _timeToMinutesTD(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _loadSlots() async {
    if (selectedService == null || !selectedService!.hasFixedSlots) return;
    setState(() => loadingSlots = true);
    try {
      final dateStr = selectedDate.toIso8601String().split('T')[0];
      final res = await api.get(
        '/services/${selectedService!.id}/slots?date=$dateStr&party_size=$partySize&reservation_units=$reservationUnits',
      );
      if (!mounted) return;
      final list =
          (res['slots'] as List?)?.map((s) => TimeSlot.fromJson(s)).toList() ??
          [];
      if (mounted) {
        setState(() {
          timeSlots = list.where((s) => s.isActive && s.isAvailable).toList();
          loadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loadingSlots = false);
    }
  }

  Future<void> _submitBooking() async {
    if (selectedService == null) {
      _showSnack('Please select a service');
      return;
    }
    if (selectedService!.hasFixedSlots && selectedSlot == null) {
      _showSnack('Please select a time slot');
      return;
    }
    if (selectedService!.bookingMode == 'stay' &&
        !selectedCheckout.isAfter(selectedDate)) {
      _showSnack('Check-out must be after check-in');
      return;
    }
    if (nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your name');
      return;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your phone number');
      return;
    }

    setState(() => submitting = true);
    try {
      final Map<String, dynamic> body = {
        'service_id': selectedService!.id,
        'customer_name': nameCtrl.text.trim(),
        'customer_phone': phoneCtrl.text.trim(),
        'customer_email': emailCtrl.text.trim().isEmpty
            ? null
            : emailCtrl.text.trim(),
        'booking_date': selectedDate.toIso8601String().split('T')[0],
        'client_reference': _clientReference,
        'party_size': partySize,
        'reservation_units': reservationUnits,
        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      };

      if (selectedService!.bookingMode == 'stay') {
        body['check_in_date'] = selectedDate.toIso8601String().split('T')[0];
        body['check_out_date'] = selectedCheckout.toIso8601String().split(
          'T',
        )[0];
      }
      if (selectedService!.bookingMode == 'seat' &&
          seatLabelsCtrl.text.trim().isNotEmpty) {
        body['seat_labels'] = seatLabelsCtrl.text
            .split(',')
            .map((seat) => seat.trim().toUpperCase())
            .where((seat) => seat.isNotEmpty)
            .toList();
      }

      if (selectedService!.hasFixedSlots && selectedSlot != null) {
        body['time_slot_id'] = selectedSlot!.id;
        body['start_time'] = selectedSlot!.startTime;
      } else {
        body['start_time'] =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      }

      final res = await api.post(
        '/businesses/${widget.business.slug}/bookings',
        body: body,
      );
      if (!mounted) return;

      _showSnack(
        res['duplicate'] == true
            ? 'This booking request was already sent.'
            : 'Booking request sent. Pay the business directly after confirmation.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => submitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.success),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    notesCtrl.dispose();
    seatLabelsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Book — ${widget.business.name}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : services.isEmpty
          ? const Center(
              child: Text(
                'No services available',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader(
                  Icons.medical_services_outlined,
                  'Select Service',
                ),
                const SizedBox(height: 10),
                ...services.map((s) => _serviceCard(s)),
                const SizedBox(height: 20),

                _sectionHeader(Icons.calendar_month_rounded, 'Date & Time'),
                const SizedBox(height: 10),
                _dateTimeRow(),
                if (selectedService != null) ...[
                  const SizedBox(height: 12),
                  _modeInputs(selectedService!),
                ],
                if (selectedService != null && !selectedService!.hasFixedSlots)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Duration: ${selectedService!.duration} min',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                if (selectedService != null &&
                    selectedService!.hasFixedSlots) ...[
                  const SizedBox(height: 16),
                  _slotsSection(),
                ],
                const SizedBox(height: 24),

                _sectionHeader(Icons.person_outline_rounded, 'Your Details'),
                const SizedBox(height: 10),
                _buildTextField(nameCtrl, 'Full Name *', Icons.person_outline),
                const SizedBox(height: 10),
                _buildTextField(
                  phoneCtrl,
                  'Phone Number *',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  emailCtrl,
                  'Email (optional)',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  notesCtrl,
                  'Notes (optional)',
                  Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Offline payment mode
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 18,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Flexible(
                        child: Text(
                          'Cash directly to business',
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
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: submitting ? null : _submitBooking,
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
                        : const Text(
                            'Submit Booking Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _serviceCard(Service s) {
    final selected = selectedService?.id == s.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedService = s;
          selectedSlot = null;
          partySize = 1;
          reservationUnits = 1;
          seatLabelsCtrl.clear();
          final mins = s.duration;
          final endMin = _timeToMinutesTD(startTime) + mins;
          endTime = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
        });
        if (s.hasFixedSlots) _loadSlots();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                s.bookingMode == 'stay'
                    ? Icons.hotel_outlined
                    : s.bookingMode == 'seat'
                    ? Icons.event_seat_outlined
                    : s.hasFixedSlots
                    ? Icons.schedule_rounded
                    : Icons.medical_services_outlined,
                color: selected ? Colors.white : AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (s.bookingMode != 'appointment')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.bookingMode == 'stay'
                                ? 'Stay'
                                : s.bookingMode == 'seat'
                                ? 'Seats'
                                : 'Slots',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if ((s.description ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        s.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (s.duration > 0 && s.bookingMode != 'stay')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${s.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '₹${s.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  '/${s.priceUnit}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeRow() {
    final isStay = selectedService?.bookingMode == 'stay';
    return Row(
      children: [
        Expanded(
          child: _buildPickerField(
            isStay ? 'Check-in' : 'Date',
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            Icons.calendar_today,
            _pickDate,
          ),
        ),
        if (!isStay &&
            (selectedService == null || !selectedService!.hasFixedSlots)) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildPickerField(
              'Start',
              startTime.format(context),
              Icons.access_time,
              () => _pickTime(isStart: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPickerField(
              'End',
              endTime.format(context),
              Icons.access_time,
              () => _pickTime(isStart: false),
            ),
          ),
        ],
      ],
    );
  }

  Widget _modeInputs(Service service) {
    if (service.bookingMode == 'stay') {
      final nights = selectedCheckout.difference(selectedDate).inDays;
      return Column(
        children: [
          _buildPickerField(
            'Check-out',
            '${selectedCheckout.day}/${selectedCheckout.month}/${selectedCheckout.year} · $nights night${nights == 1 ? '' : 's'}',
            Icons.hotel_outlined,
            _pickCheckout,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _countPicker(
                  service.unitLabel ?? 'Rooms / units',
                  reservationUnits,
                  service.inventoryUnits,
                  (value) => setState(() => reservationUnits = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _countPicker(
                  'Guests',
                  partySize,
                  20,
                  (value) => setState(() => partySize = value),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (service.bookingMode == 'slot') {
      return Row(
        children: [
          Expanded(
            child: _countPicker(
              service.unitLabel ?? 'Courts / units',
              reservationUnits,
              service.inventoryUnits,
              (value) {
                setState(() {
                  reservationUnits = value;
                  selectedSlot = null;
                });
                _loadSlots();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _countPicker(
              'Participants',
              partySize,
              100,
              (value) => setState(() => partySize = value),
            ),
          ),
        ],
      );
    }

    if (service.bookingMode == 'seat') {
      return Column(
        children: [
          _countPicker(
            'Seats / guests',
            partySize,
            service.capacity < 1
                ? 1
                : (service.capacity > 100 ? 100 : service.capacity),
            (value) {
              setState(() {
                partySize = value;
                selectedSlot = null;
              });
              _loadSlots();
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            seatLabelsCtrl,
            'Preferred seat numbers, comma separated (optional)',
            Icons.event_seat_outlined,
          ),
        ],
      );
    }

    return _countPicker(
      'People',
      partySize,
      service.capacity < 1
          ? 1
          : (service.capacity > 100 ? 100 : service.capacity),
      (value) => setState(() => partySize = value),
    );
  }

  Widget _countPicker(
    String label,
    int value,
    int maximum,
    ValueChanged<int> onChanged,
  ) {
    final safeMaximum = maximum < 1 ? 1 : maximum;
    final safeValue = value < 1
        ? 1
        : (value > safeMaximum ? safeMaximum : value);
    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: List.generate(
        safeMaximum,
        (index) =>
            DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
      ),
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }

  Widget _slotsSection() {
    if (loadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (timeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No slots available for this date',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different date',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final morning = timeSlots
        .where((s) => _timeOfDayLabel(s.startTime) == 'Morning')
        .toList();
    final afternoon = timeSlots
        .where((s) => _timeOfDayLabel(s.startTime) == 'Afternoon')
        .toList();
    final evening = timeSlots
        .where((s) => _timeOfDayLabel(s.startTime) == 'Evening')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morning.isNotEmpty)
          _slotGroup(
            'Morning',
            Icons.wb_sunny_rounded,
            const Color(0xFFF59E0B),
            morning,
          ),
        if (afternoon.isNotEmpty)
          _slotGroup(
            'Afternoon',
            Icons.wb_cloudy_rounded,
            const Color(0xFFEF4444),
            afternoon,
          ),
        if (evening.isNotEmpty)
          _slotGroup(
            'Evening',
            Icons.nights_stay_rounded,
            const Color(0xFF6366F1),
            evening,
          ),
      ],
    );
  }

  Widget _slotGroup(
    String label,
    IconData icon,
    Color color,
    List<TimeSlot> slots,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: color.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) => _slotCard(slot)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(TimeSlot slot) {
    final selected = selectedSlot?.id == slot.id;
    final capacityPct = slot.available / slot.capacity;
    final isLow = slot.available <= 2;

    return GestureDetector(
      onTap: () => setState(() => selectedSlot = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - 56) / 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              _formatTime(slot.startTime),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(slot.endTime),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white70 : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: capacityPct,
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : (isLow ? AppTheme.error : AppTheme.success),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLow ? 'Only ${slot.available} left' : '${slot.available} left',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white70
                    : (isLow ? AppTheme.error : AppTheme.textMuted),
              ),
            ),
            if (slot.price > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '₹${slot.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
