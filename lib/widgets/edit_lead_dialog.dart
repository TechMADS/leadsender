import 'package:flutter/material.dart';
import 'package:leadsender/theme/color.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/dropdown_provider.dart';
import '../providers/lead_provider.dart';
import '../services/lead_sheet_service.dart';

class EditLeadDialog extends StatefulWidget {
  final Lead lead;
  const EditLeadDialog({super.key, required this.lead});

  @override
  State<EditLeadDialog> createState() => _EditLeadDialogState();
}

class _EditLeadDialogState extends State<EditLeadDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.lead.name ?? '');
  late final TextEditingController _location = TextEditingController(text: widget.lead.location ?? '');
  late final TextEditingController _enquiry = TextEditingController(text: widget.lead.enquiry ?? '');

  late String _conversionStatus;
  String? _siteStatus;
  String? _source;
  late LeadStatus _status;

  List<String> _siteOpts = [];
  List<String> _sourceOpts = [];
  bool _loading = true;

  final _sheetService = LeadSheetService();

  @override
  void initState() {
    super.initState();
    final dp = context.read<DropdownProvider>();

    // Load current values
    _conversionStatus = widget.lead.conversionStatus;
    if (!dp.options.contains(_conversionStatus)) {
      _conversionStatus = dp.options.isNotEmpty ? dp.options.first : 'newLead';
    }

    _siteStatus = widget.lead.siteStatus;
    _source = widget.lead.source;
    _status = widget.lead.status;

    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final site = await _sheetService.fetchDropdown('SiteStatus');
      final source = await _sheetService.fetchDropdown('Source');
      if (mounted) {
        setState(() {
          _siteOpts = site;
          _sourceOpts = source;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _enquiry.dispose();
    super.dispose();
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.red),)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (val != null && val.isNotEmpty && mounted) {
      await _sheetService.addDropdownOption(type, val);
      onAdded(val);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: const Text('This will permanently remove this lead from the sheet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<LeadProvider>().deleteLead(widget.lead);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = context.watch<DropdownProvider>().options;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Expanded(child: Text(widget.lead.normalizedNumber)),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name',fillColor: Colors.white,
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

            DropdownButtonFormField<LeadStatus>(
              dropdownColor: Colors.white,
              value: _status,
              decoration: const InputDecoration(labelText: 'Lead Status', fillColor: Colors.white),
              items: LeadStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),

            // Conversion
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    value: options.contains(_conversionStatus) ? _conversionStatus : null,
                    decoration: const InputDecoration(labelText: 'Conversion', fillColor: Colors.white),
                    items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _conversionStatus = v ?? _conversionStatus),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _addOption('Conversion', (val) async {
                    await context.read<DropdownProvider>().loadOptions();
                    setState(() => _conversionStatus = val);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Site Status
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    value: _siteOpts.contains(_siteStatus) ? _siteStatus : null,
                    decoration: const InputDecoration(labelText: 'Site Status', fillColor: Colors.white),
                    items: _siteOpts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _siteStatus = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _addOption('SiteStatus', (val) {
                    setState(() {
                      _siteOpts.add(val);
                      _siteStatus = val; // Instantly select the new item
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Source
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    value: _sourceOpts.contains(_source) ? _source : null,
                    decoration: const InputDecoration(labelText: 'Source', fillColor: Colors.white),
                    items: _sourceOpts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _source = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => _addOption('Source', (val) {
                    setState(() {
                      _sourceOpts.add(val);
                      _source = val; // Instantly select the new item
                    });
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _location,
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
            TextField(
              controller: _enquiry,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Enquiry', fillColor: Colors.white,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.red),),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: primaryColor),
          onPressed: () => Navigator.pop(context, {
            'conversionStatus': _conversionStatus,
            'siteStatus': _siteStatus,
            'source': _source,
            'status': _status,
            'name': _name.text.trim(),
            'location': _location.text.trim(),
            'enquiry': _enquiry.text.trim(),
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/lead.dart';
// import '../providers/dropdown_provider.dart';
// import '../providers/lead_provider.dart';
// import '../services/lead_sheet_service.dart';
//
// class EditLeadDialog extends StatefulWidget {
//   final Lead lead;
//   const EditLeadDialog({super.key, required this.lead});
//
//   @override
//   State<EditLeadDialog> createState() => _EditLeadDialogState();
// }
//
// class _EditLeadDialogState extends State<EditLeadDialog> {
//   late final TextEditingController _name = TextEditingController(text: widget.lead.name ?? '');
//   late final TextEditingController _location = TextEditingController(text: widget.lead.location ?? '');
//   late final TextEditingController _enquiry = TextEditingController(text: widget.lead.enquiry ?? '');
//
//   late String _conversionStatus;
//   String? _siteStatus;
//   String? _source;
//   late LeadStatus _status;
//
//   List<String> _siteOpts = [];
//   List<String> _sourceOpts = [];
//   bool _loading = true;
//
//   final _sheetService = LeadSheetService();
//
//   @override
//   void initState() {
//     super.initState();
//     final dp = context.read<DropdownProvider>();
//     _conversionStatus = widget.lead.conversionStatus;
//     if (!dp.options.contains(_conversionStatus)) {
//       _conversionStatus = dp.options.isNotEmpty ? dp.options.first : 'newLead';
//     }
//
//     _siteStatus = widget.lead.siteStatus;
//     _source = widget.lead.source;
//     _status = widget.lead.status;
//
//     _loadDropdowns();
//   }
//
//   Future<void> _loadDropdowns() async {
//     try {
//       final site = await _sheetService.fetchDropdown('SiteStatus');
//       final source = await _sheetService.fetchDropdown('Source');
//       if (mounted) {
//         setState(() {
//           _siteOpts = site;
//           _sourceOpts = source;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   @override
//   void dispose() {
//     _name.dispose();
//     _location.dispose();
//     _enquiry.dispose();
//     super.dispose();
//   }
//
//   Future<void> _addOption(String type, Function(String) onAdded) async {
//     final ctrl = TextEditingController();
//     final val = await showDialog<String>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text('Add $type Option'),
//         content: TextField(controller: ctrl),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//           FilledButton(
//             onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//
//     if (val != null && val.isNotEmpty && mounted) {
//       await _sheetService.addDropdownOption(type, val);
//       onAdded(val);
//     }
//   }
//
//   Future<void> _confirmDelete() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Delete Lead?'),
//         content: const Text('This will permanently remove this lead from the sheet.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//
//     if (ok == true && mounted) {
//       await context.read<LeadProvider>().deleteLead(widget.lead);
//       if (mounted) Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final options = context.watch<DropdownProvider>().options;
//
//     return AlertDialog(
//       title: Row(
//         children: [
//           Expanded(child: Text(widget.lead.normalizedNumber)),
//           IconButton(
//             icon: const Icon(Icons.delete, color: Colors.red),
//             onPressed: _confirmDelete,
//           ),
//         ],
//       ),
//       content: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _name,
//               decoration: const InputDecoration(labelText: 'Name'),
//             ),
//             const SizedBox(height: 12),
//
//             // Lead Status (Sent, Pending, etc.)
//             DropdownButtonFormField<LeadStatus>(
//               value: _status,
//               decoration: const InputDecoration(labelText: 'Lead Status'),
//               items: LeadStatus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
//               onChanged: (v) => setState(() => _status = v ?? _status),
//             ),
//             const SizedBox(height: 12),
//
//             // Conversion Status
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: options.contains(_conversionStatus) ? _conversionStatus : null,
//                     decoration: const InputDecoration(labelText: 'Conversion'),
//                     items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//                     onChanged: (v) => setState(() => _conversionStatus = v ?? _conversionStatus),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add_circle, color: Colors.blue),
//                   onPressed: () => _addOption('Conversion', (val) => setState(() {
//                     context.read<DropdownProvider>().loadOptions();
//                     _conversionStatus = val;
//                   })),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // Site Status
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _siteOpts.contains(_siteStatus) ? _siteStatus : null,
//                     decoration: const InputDecoration(labelText: 'Site Status'),
//                     items: _siteOpts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//                     onChanged: (v) => setState(() => _siteStatus = v),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add_circle, color: Colors.blue),
//                   onPressed: () => _addOption('SiteStatus', (val) => setState(() {
//                     _siteOpts.add(val);
//                     _siteStatus = val;
//                   })),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             // Source
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _sourceOpts.contains(_source) ? _source : null,
//                     decoration: const InputDecoration(labelText: 'Source'),
//                     items: _sourceOpts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
//                     onChanged: (v) => setState(() => _source = v),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add_circle, color: Colors.blue),
//                   onPressed: () => _addOption('Source', (val) => setState(() {
//                     _sourceOpts.add(val);
//                     _source = val;
//                   })),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//             TextField(
//               controller: _location,
//               decoration: const InputDecoration(labelText: 'Location'),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _enquiry,
//               maxLines: 3,
//               decoration: const InputDecoration(labelText: 'Enquiry'),
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         FilledButton(
//           onPressed: () => Navigator.pop(context, {
//             'conversionStatus': _conversionStatus,
//             'siteStatus': _siteStatus,
//             'source': _source,
//             'status': _status,
//             'name': _name.text.trim(),
//             'location': _location.text.trim(),
//             'enquiry': _enquiry.text.trim(),
//           }),
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }

