import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';

class BusinessEditScreen extends StatefulWidget {
  final Business business;

  const BusinessEditScreen({super.key, required this.business});

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business.name);
    _descriptionController = TextEditingController(text: widget.business.description ?? '');
    _phoneController = TextEditingController(text: widget.business.phone ?? '');
    _whatsappController = TextEditingController(text: widget.business.whatsapp ?? '');
    _emailController = TextEditingController(text: widget.business.email ?? '');
    _websiteController = TextEditingController(text: widget.business.website ?? '');
    _addressController = TextEditingController(text: widget.business.address ?? '');
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon — full edit is admin-only')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.business.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField('Business Name', _nameController),
          _buildField('Description', _descriptionController, maxLines: 3),
          _buildField('Phone', _phoneController, keyboardType: TextInputType.phone),
          _buildField('WhatsApp', _whatsappController, keyboardType: TextInputType.phone),
          _buildField('Email', _emailController, keyboardType: TextInputType.emailAddress),
          _buildField('Website', _websiteController, keyboardType: TextInputType.url),
          _buildField('Address', _addressController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
