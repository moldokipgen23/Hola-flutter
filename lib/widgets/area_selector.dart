import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';

class AreaSelection {
  final String pincode;
  final String label;
  final bool serviceable;

  const AreaSelection({
    required this.pincode,
    required this.label,
    required this.serviceable,
  });
}

class AreaSelector extends StatefulWidget {
  final Color foregroundColor;
  final Color backgroundColor;
  final ValueChanged<AreaSelection?>? onChanged;

  const AreaSelector({
    super.key,
    this.foregroundColor = Colors.white,
    this.backgroundColor = const Color(0x33FFFFFF),
    this.onChanged,
  });

  @override
  State<AreaSelector> createState() => _AreaSelectorState();
}

class _AreaSelectorState extends State<AreaSelector> {
  AreaSelection? _selection;

  @override
  void initState() {
    super.initState();
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final pincode = prefs.getString('selected_pincode');
    final label = prefs.getString('selected_area_label');
    if (!mounted || pincode == null || label == null) return;
    setState(() {
      _selection = AreaSelection(
        pincode: pincode,
        label: label,
        serviceable: prefs.getBool('selected_area_serviceable') ?? false,
      );
    });
  }

  Future<void> _saveSelection(AreaSelection selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_pincode', selection.pincode);
    await prefs.setString('selected_area_label', selection.label);
    await prefs.setBool('selected_area_serviceable', selection.serviceable);
    if (!mounted) return;
    setState(() => _selection = selection);
    widget.onChanged?.call(selection);
  }

  Future<void> _clearSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_pincode');
    await prefs.remove('selected_area_label');
    await prefs.remove('selected_area_serviceable');
    if (!mounted) return;
    setState(() => _selection = null);
    widget.onChanged?.call(null);
  }

  Future<void> _openPicker() async {
    final controller = TextEditingController(text: _selection?.pincode ?? '');
    String? message;
    bool checking = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> checkArea() async {
            final pincode = controller.text.trim();
            if (pincode.length != 6) {
              setSheetState(() => message = 'Enter a valid 6-digit pincode.');
              return;
            }
            setSheetState(() {
              checking = true;
              message = null;
            });
            try {
              final result = await api.get(
                '/pincodes/lookup',
                queryParams: {'pincode': pincode},
              );
              final locality = result['locality']?.toString().trim();
              final district = result['district']?.toString().trim();
              final parts = <String>[
                if (locality != null && locality.isNotEmpty) locality,
                if (district != null &&
                    district.isNotEmpty &&
                    district != locality)
                  district,
              ];
              final selection = AreaSelection(
                pincode: pincode,
                label: parts.isEmpty ? pincode : parts.join(', '),
                serviceable: result['serviceable'] == true,
              );
              await _saveSelection(selection);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            } catch (_) {
              setSheetState(() {
                checking = false;
                message = 'We could not find that pincode. Please try again.';
              });
            }
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Set your area',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This helps you recognise nearby businesses. Delivery and booking coverage is confirmed with each vendor.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      hintText: 'Enter 6-digit pincode',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      counterText: '',
                    ),
                    onSubmitted: (_) => checkArea(),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: checking ? null : checkArea,
                      icon: checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(checking ? 'Checking…' : 'Use this area'),
                    ),
                  ),
                  if (_selection != null)
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await _clearSelection();
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        child: const Text('Show all areas'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _selection?.label ?? 'Set your area';
    return Material(
      color: widget.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _openPicker,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: widget.foregroundColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: widget.foregroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
