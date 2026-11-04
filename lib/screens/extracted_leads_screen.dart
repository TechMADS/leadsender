import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lead_provider.dart';
import '../theme/color.dart';
import '../widgets/lead_tile.dart';
import '../widgets/edit_lead_dialog.dart'; // ← Import shared dialog
import 'message_preview_screen.dart';
import 'messaging_queue_screen.dart';

class ExtractedLeadsScreen extends StatefulWidget {
  const ExtractedLeadsScreen({super.key});

  @override
  State<ExtractedLeadsScreen> createState() => _ExtractedLeadsScreenState();
}

class _ExtractedLeadsScreenState extends State<ExtractedLeadsScreen> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadProvider>();
    final batch = provider.batch;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Extracted Leads',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: batch.isEmpty
          ? const Center(child: Text('No valid numbers found.'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => setState(
                        () => _selected.addAll(
                      List.generate(batch.length, (i) => i),
                    ),
                  ),
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: const Text('Deselect All'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                    provider.removeIndices(_selected);
                    _selected.clear();
                  },
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: batch.length,
              itemBuilder: (_, i) {
                final lead = batch[i];
                return LeadTile(
                  lead: lead,
                  selected: _selected.contains(i),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(i);
                    } else {
                      _selected.remove(i);
                    }
                  }),
                  onTap: () async {
                    final result = await showDialog<Map<String, Object?>>(
                      context: context,
                      builder: (_) => EditLeadDialog(lead: lead),
                    );
                    if (result != null && context.mounted) {
                      await context.read<LeadProvider>().updateConversion(
                        lead,
                        conversionStatus: result['status'] as String?,
                        name: result['name'] as String?,
                        location: result['location'] as String?,
                        enquiry: result['enquiry'] as String?,
                      );
                    }
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessagePreviewScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.preview),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Select at least one recipient.'),
                            ),
                          );
                          return;
                        }
                        final selectedLeads = _selected.map((i) => batch[i]).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagingQueueScreen(leads: selectedLeads),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}