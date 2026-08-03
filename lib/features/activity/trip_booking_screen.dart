import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../theme.dart';

class TripBookingScreen extends StatefulWidget {
  final Business business;
  const TripBookingScreen({super.key, required this.business});

  @override
  State<TripBookingScreen> createState() => _TripBookingScreenState();
}

class _TripBookingScreenState extends State<TripBookingScreen> {
  final pickupCtrl = TextEditingController();
  final dropCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final loadDescriptionCtrl = TextEditingController();
  final loadWeightCtrl = TextEditingController();
  List<Vehicle> vehicles = [];
  Vehicle? selectedVehicle;
  double? estimatedFare;
  int seatsRequired = 1;
  bool scheduleLater = false;
  DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));
  DateTime? returnAt;
  bool loading = true;
  bool submitting = false;
  late final String _clientReference;

  @override
  void initState() {
    super.initState();
    _clientReference =
        'app-trip-${widget.business.id}-${DateTime.now().microsecondsSinceEpoch}';
    distanceCtrl.addListener(_calculateFare);
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final response = await api.get(
        '/businesses/${widget.business.slug}/vehicles',
      );
      final list = (response['vehicles'] as List? ?? [])
          .map((item) => Vehicle.fromJson(item))
          .toList();
      if (mounted) {
        setState(() {
          vehicles = list;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _calculateFare() {
    final distance = double.tryParse(distanceCtrl.text);
    setState(() {
      estimatedFare =
          selectedVehicle != null && distance != null && distance > 0
          ? selectedVehicle!.estimatedFare(distance)
          : null;
    });
  }

  Future<void> _pickSchedule({bool isReturn = false}) async {
    final initial = isReturn
        ? returnAt ?? scheduledAt.add(const Duration(hours: 4))
        : scheduledAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isReturn) {
        returnAt = value;
      } else {
        scheduledAt = value;
        if (returnAt != null && !returnAt!.isAfter(value)) returnAt = null;
      }
    });
  }

  String _dateTimeLabel(DateTime value) {
    final time = TimeOfDay.fromDateTime(value).format(context);
    return '${value.day}/${value.month}/${value.year} · $time';
  }

  Future<void> _submitTrip() async {
    final vehicle = selectedVehicle;
    if (vehicle == null) return _message('Please select an available vehicle');
    if (pickupCtrl.text.trim().isEmpty || dropCtrl.text.trim().isEmpty) {
      return _message('Please enter pickup and drop locations');
    }
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      return _message('Please enter your name and phone');
    }
    if (vehicle.serviceMode != 'taxi' && !scheduleLater) {
      return _message('Please choose a pickup date and time');
    }
    if (vehicle.serviceMode == 'rental' && returnAt == null) {
      return _message('Please choose a return date and time');
    }
    if (vehicle.serviceMode == 'goods' &&
        loadDescriptionCtrl.text.trim().isEmpty) {
      return _message('Please describe the goods or load');
    }

    setState(() => submitting = true);
    try {
      final response = await api.post(
        '/businesses/${widget.business.slug}/trips',
        body: {
          'vehicle_id': vehicle.id,
          'customer_name': nameCtrl.text.trim(),
          'customer_phone': phoneCtrl.text.trim(),
          'customer_email': emailCtrl.text.trim().isEmpty
              ? null
              : emailCtrl.text.trim(),
          'pickup_location': pickupCtrl.text.trim(),
          'drop_location': dropCtrl.text.trim(),
          'distance_km': double.tryParse(distanceCtrl.text),
          'seats_required': seatsRequired,
          'scheduled_at': (scheduleLater || vehicle.serviceMode != 'taxi')
              ? scheduledAt.toIso8601String()
              : null,
          'return_at': vehicle.serviceMode == 'rental'
              ? returnAt?.toIso8601String()
              : null,
          'load_description': vehicle.serviceMode == 'goods'
              ? loadDescriptionCtrl.text.trim()
              : null,
          'load_weight': vehicle.serviceMode == 'goods'
              ? double.tryParse(loadWeightCtrl.text)
              : null,
          'client_reference': _clientReference,
          'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['duplicate'] == true
                ? 'This transport request was already sent.'
                : 'Request sent. Confirm the fare and pay the operator directly.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => submitting = false);
        _message(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    for (final controller in [
      pickupCtrl,
      dropCtrl,
      distanceCtrl,
      nameCtrl,
      phoneCtrl,
      emailCtrl,
      notesCtrl,
      loadDescriptionCtrl,
      loadWeightCtrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = selectedVehicle;
    final quoteRequired =
        vehicle?.requiresQuote == true ||
        vehicle?.serviceMode == 'goods' ||
        vehicle?.serviceMode == 'rental' ||
        estimatedFare == null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Transport · ${widget.business.name}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : vehicles.isEmpty
          ? const Center(child: Text('No transport options available'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heading('Select transport'),
                const SizedBox(height: 8),
                ...vehicles.map(_vehicleCard),
                const SizedBox(height: 18),
                _heading('Journey details'),
                const SizedBox(height: 8),
                _field(
                  pickupCtrl,
                  'Pickup location *',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                _field(dropCtrl, 'Drop location *', Icons.flag_outlined),
                const SizedBox(height: 10),
                _field(
                  distanceCtrl,
                  'Approx. distance in km (optional)',
                  Icons.straighten,
                  keyboardType: TextInputType.number,
                ),
                if (vehicle != null && vehicle.serviceMode != 'goods') ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: seatsRequired,
                    decoration: _inputDecoration(
                      'Passengers',
                      Icons.airline_seat_recline_normal,
                    ),
                    items: List.generate(
                      vehicle.seats,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => seatsRequired = value ?? 1),
                  ),
                ],
                if (vehicle != null) ...[
                  const SizedBox(height: 12),
                  if (vehicle.serviceMode == 'taxi')
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      title: const Text('Schedule for later'),
                      subtitle: const Text('Turn off for an immediate request'),
                      value: scheduleLater,
                      onChanged: (value) =>
                          setState(() => scheduleLater = value),
                    ),
                  if (scheduleLater || vehicle.serviceMode != 'taxi') ...[
                    const SizedBox(height: 10),
                    _dateButton('Pickup', scheduledAt, () => _pickSchedule()),
                  ],
                  if (vehicle.serviceMode == 'rental') ...[
                    const SizedBox(height: 10),
                    _dateButton(
                      'Return',
                      returnAt,
                      () => _pickSchedule(isReturn: true),
                    ),
                  ],
                  if (vehicle.serviceMode == 'goods') ...[
                    const SizedBox(height: 10),
                    _field(
                      loadDescriptionCtrl,
                      'Goods / load description *',
                      Icons.inventory_2_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      loadWeightCtrl,
                      'Approx. load (${vehicle.capacityUnit})',
                      Icons.scale_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
                if (estimatedFare != null || vehicle != null) ...[
                  const SizedBox(height: 12),
                  _fareCard(quoteRequired),
                ],
                const SizedBox(height: 20),
                _heading('Your details'),
                const SizedBox(height: 8),
                _field(nameCtrl, 'Full name *', Icons.person_outline),
                const SizedBox(height: 10),
                _field(
                  phoneCtrl,
                  'Phone number *',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _field(
                  emailCtrl,
                  'Email (optional)',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _field(
                  notesCtrl,
                  'Notes (optional)',
                  Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _offlinePaymentCard(),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submitting ? null : _submitTrip,
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
                            quoteRequired
                                ? 'Send request for quote'
                                : 'Send request · Est. ₹${estimatedFare!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _vehicleCard(Vehicle vehicle) {
    final selected = selectedVehicle?.id == vehicle.id;
    final capacity =
        vehicle.serviceMode == 'goods' && vehicle.capacityValue != null
        ? '${vehicle.capacityValue!.toStringAsFixed(0)} ${vehicle.capacityUnit}'
        : '${vehicle.seats} seats';
    return Opacity(
      opacity: vehicle.isRequestable ? 1 : 0.55,
      child: GestureDetector(
        onTap: vehicle.isRequestable
            ? () {
                setState(() {
                  selectedVehicle = vehicle;
                  seatsRequired = 1;
                  scheduleLater = vehicle.serviceMode != 'taxi';
                  returnAt = null;
                });
                _calculateFare();
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(vehicle.typeIcon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${vehicle.serviceMode.toUpperCase()} · $capacity',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (!vehicle.isRequestable)
                      const Text(
                        'Not accepting requests',
                        style: TextStyle(fontSize: 11, color: Colors.red),
                      ),
                  ],
                ),
              ),
              Text(
                vehicle.requiresQuote
                    ? 'Quote'
                    : 'From ₹${vehicle.baseFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value == null
              ? 'Choose $label date and time *'
              : '$label · ${_dateTimeLabel(value)}',
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        alignment: Alignment.centerLeft,
        side: const BorderSide(color: AppTheme.border),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _fareCard(bool quoteRequired) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quoteRequired
                  ? 'Operator will confirm the final fare'
                  : 'Fare shown is an estimate; confirm with the operator',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (estimatedFare != null)
            Text(
              '₹${estimatedFare!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _offlinePaymentCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.payments_outlined, color: AppTheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline payment only',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Pay cash directly to the operator. Eiho One does not collect payment.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(hint, icon),
    );
  }
}
