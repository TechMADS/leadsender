import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/dropdown_provider.dart';
import '../providers/lead_provider.dart';

class EditLeadDialog extends StatefulWidget {
  final Lead lead;
  const EditLeadDialog({super.key, required this.lead});

  @override
  State<EditLeadDialog> createState() => _EditLeadDialogState();
}

class _EditLeadDialogState extends State<EditLeadDialog> {
  late String _status;
  late final TextEditingController _name = TextEditingController(text: widget.lead.name ?? '');
  late final TextEditingController _location = TextEditingController(text: widget.lead.location ?? '');
  late final TextEditingController _enquiry = TextEditingController(text: widget.lead.enquiry ?? '');

  @override
  void initState() {
    super.initState();
    final dp = context.read<DropdownProvider>();
    _status = widget.lead.conversionStatus;
    if (!dp.options.contains(_status)) {
      _status = dp.options.isNotEmpty ? dp.options.first : 'newLead';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _enquiry.dispose();
    super.dispose();
  }

  Future<void> _addNewOption() async {
    final controller = TextEditingController();
    final newOpt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Option'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Follow Up'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newOpt != null && newOpt.isNotEmpty && mounted) {
      await context.read<DropdownProvider>().addOption(newOpt);
      setState(() => _status = newOpt);
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
      if (mounted) Navigator.pop(context); // Close the edit dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = context.watch<DropdownProvider>().options;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.lead.normalizedNumber)),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: 'Delete Lead',
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: options.contains(_status) ? _status : null,
                    decoration: const InputDecoration(labelText: 'Conversion'),
                    items: options
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: _addNewOption,
                  tooltip: 'Add new option',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _enquiry,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Enquiry'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
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