import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/business_profile.dart';
import '../providers/settings_provider.dart';
import '../theme/color.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopName,
      _intro,
      _address,
      _contact,
      _catalogue,
      _website,
      _hours,
      _template;
  String _cc = '+91';

  @override
  void initState() {
    super.initState();
    final p = context.read<SettingsProvider>().profile;
    _shopName = TextEditingController(text: p.shopName);
    _intro = TextEditingController(text: p.introduction);
    _address = TextEditingController(text: p.address);
    _contact = TextEditingController(text: p.contactNumber);
    _catalogue = TextEditingController(text: p.catalogueUrl);
    _website = TextEditingController(text: p.websiteUrl);
    _hours = TextEditingController(text: p.businessHours);
    _template = TextEditingController(text: p.template);
    _cc = p.defaultCountryCode;
  }

  @override
  void dispose() {
    for (final c in [
      _shopName,
      _intro,
      _address,
      _contact,
      _catalogue,
      _website,
      _hours,
      _template,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = BusinessProfile(
      shopName: _shopName.text.trim(),
      introduction: _intro.text.trim(),
      address: _address.text.trim(),
      contactNumber: _contact.text.trim(),
      catalogueUrl: _catalogue.text.trim(),
      websiteUrl: _website.text.trim(),
      businessHours: _hours.text.trim(),
      template: _template.text,
      defaultCountryCode: _cc,
    );
    await context.read<SettingsProvider>().update(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Business Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),), leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_shopName, 'Business / Shop Name', required: true),
            _field(_intro, 'Short Introduction', maxLines: 3),
            _field(_address, 'Shop Address', maxLines: 2),
            _field(_contact, 'Business Contact Number'),
            _field(
              _catalogue,
              'Catalogue URL',
              keyboard: TextInputType.url,
              validator: _urlValidator,
            ),
            _field(
              _website,
              'Website URL (optional)',
              keyboard: TextInputType.url,
              validator: (v) =>
              v == null || v.trim().isEmpty ? null : _urlValidator(v),
            ),
            _field(_hours, 'Business Hours (optional)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _cc,
              decoration: const InputDecoration(labelText: 'Default Country Code'),
              items: const [
                DropdownMenuItem(value: '+91', child: Text('India (+91)')),
              ],
              onChanged: (v) => setState(() => _cc = v ?? '+91'),
            ),
            const SizedBox(height: 16),
            _field(_template, 'Message Template', maxLines: 12),
            const SizedBox(height: 8),
            Text(
              'Placeholders: {shop_name}, {introduction}, {shop_address}, '
                  '{contact_number}, {catalogue_url}, {website_line}, '
                  '{lead_name}, {phone_number}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController c,
      String label, {
        int maxLines = 1,
        TextInputType? keyboard,
        bool required = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null),
        decoration: InputDecoration(labelText: label, fillColor: Colors.white),
      ),
    );
  }

  String? _urlValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final uri = Uri.tryParse(v.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }
}