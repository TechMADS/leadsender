import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/template_provider.dart';
import '../services/lead_sheet_service.dart';
import '../services/message_template_service.dart';
import '../services/whatsapp_launcher.dart';
import '../theme/color.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _enquiryCtrl = TextEditingController();

  String? _conversionStatus;
  String? _siteStatus;
  String? _source;

  final _sheetService = LeadSheetService();
  List<String> _conversionOpts = [];
  List<String> _siteOpts = [];
  List<String> _sourceOpts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final conv = await _sheetService.fetchDropdownOptions();
      final site = await _sheetService.fetchDropdown('SiteStatus');
      final source = await _sheetService.fetchDropdown('Source');
      if (mounted) {
        setState(() {
          _conversionOpts = conv;
          _siteOpts = site;
          _sourceOpts = source;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addOption(String type, Function(String) onAdded) async {
    final ctrl = TextEditingController();
    final val = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Add $type Option'),
        content: TextField(controller: ctrl, decoration: InputDecoration(fillColor: Colors.white,
          filled: true,
          labelStyle: TextStyle(color: Colors.black),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
          ),

          // 2. Border configuration when the field is NOT selected (Optional)
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.red),),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (val != null && val.isNotEmpty) {
      await _sheetService.addDropdownOption(type, val);
      onAdded(val);
    }
  }

  Future<void> _saveAndSend() async {
    if (!_formKey.currentState!.validate()) return;

    final lead = Lead(
      normalizedNumber: '+91${_phoneCtrl.text.trim()}',
      originalNumber: _phoneCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      enquiry: _enquiryCtrl.text.trim(),
      conversionStatus: _conversionStatus ?? 'newLead',
      siteStatus: _siteStatus,
      source: _source,
      importedAt: DateTime.now(),
    );

    try {
      // 1. Save to sheet
      await context.read<LeadProvider>().addLead(lead);
      if (!mounted) return;

      // 2. Open WhatsApp
      final profile = context.read<SettingsProvider>().profile;
      final template =
          context.read<TemplateProvider>().selected?.body ?? profile.template;
      final message = MessageTemplateService.renderBody(
        body: template,
        profile: profile,
        lead: lead,
      );

      final opened = await WhatsAppLauncher.openChat(
        e164Number: lead.normalizedNumber,
        message: message,
      );

      if (opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead saved & WhatsApp opened!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add Lead',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                labelText: 'Phone Number (10 digits)',
                fillColor: Colors.white,
                filled: true,
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
                ),

                // 2. Border configuration when the field is NOT selected (Optional)
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 10) ? 'Enter valid number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name', fillColor: Colors.white,
                filled: true,
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
                ),

                // 2. Border configuration when the field is NOT selected (Optional)
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location', fillColor: Colors.white,
                filled: true,
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
                ),

                // 2. Border configuration when the field is NOT selected (Optional)
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),),
            ),
            const SizedBox(height: 12),

            // Conversion Status
            _buildDropdownRow(
              'Conversion Status',
              _conversionOpts,
              _conversionStatus,
              (v) => setState(() => _conversionStatus = v),
              () {
                _addOption('Conversion', (val) {
                  setState(() {
                    _conversionOpts.add(val);
                    _conversionStatus = val; // Instantly select new option
                  });
                });
              },
            ),
            const SizedBox(height: 12),

            // Site Status
            _buildDropdownRow(
              'Site Status',
              _siteOpts,
              _siteStatus,
              (v) => setState(() => _siteStatus = v),
              () {
                _addOption('SiteStatus', (val) {
                  setState(() {
                    _siteOpts.add(val);
                    _siteStatus = val; // Instantly select new option
                  });
                });
              },
            ),
            const SizedBox(height: 12),

            // Source
            _buildDropdownRow(
              'Source',
              _sourceOpts,
              _source,
              (v) => setState(() => _source = v),
              () {
                _addOption('Source', (val) {
                  setState(() {
                    _sourceOpts.add(val);
                    _source = val; // Instantly select new option
                  });
                });
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _enquiryCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Enquiry Details', fillColor: Colors.white,
                filled: true,
                labelStyle: TextStyle(color: Colors.black),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
                ),

                // 2. Border configuration when the field is NOT selected (Optional)
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveAndSend,
              icon: const Icon(Icons.send),
              label: const Text('Save & Send WhatsApp'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(
    String label,
    List<String> options,
    String? value,
    Function(String?) onChanged,
    VoidCallback onAdd,
  ) {
    // Safety check: ensure the current value exists in the options list
    final safeValue = options.contains(value) ? value : null;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            value: safeValue,
            decoration: InputDecoration(labelText: label, fillColor: Colors.white,
              filled: true,
              labelStyle: TextStyle(color: Colors.black),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF439F3C), width: 2.0),
              ),

              // 2. Border configuration when the field is NOT selected (Optional)
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),),
            items: options
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            hint: const Text('Select an option'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: onAdd,
          tooltip: 'Add new $label',
        ),
      ],
    );
  }
}
