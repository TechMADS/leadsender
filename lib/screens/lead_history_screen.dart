import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/lead_provider.dart';
import '../providers/dropdown_provider.dart';
import '../theme/color.dart';
import '../widgets/lead_tile.dart';
import '../widgets/edit_lead_dialog.dart';

class LeadHistoryScreen extends StatefulWidget {
  const LeadHistoryScreen({super.key});

  @override
  State<LeadHistoryScreen> createState() => _LeadHistoryScreenState();
}

class _LeadHistoryScreenState extends State<LeadHistoryScreen> {
  String _query = '';
  LeadStatus? _filterStatus;
  String? _filterConversion;

  @override
  void initState() {
    super.initState();
    // Refresh dropdown options when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DropdownProvider>().loadOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadProvider>();
    final dp = context.watch<DropdownProvider>();

    final filtered = provider.history.where((l) {
      final q = _query.toLowerCase();
      final matches = q.isEmpty ||
          l.normalizedNumber.contains(q) ||
          (l.name ?? '').toLowerCase().contains(q) ||
          (l.location ?? '').toLowerCase().contains(q) ||
          (l.enquiry ?? '').toLowerCase().contains(q);

      final statusOk = _filterStatus == null || l.status == _filterStatus;
      final convOk = _filterConversion == null || l.conversionStatus == _filterConversion;

      return matches && statusOk && convOk;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Lead History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: provider.loading
                ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: provider.loading ? null : provider.loadHistory,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by number, name, location',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _filterConversion != null ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _filterConversion != null ? primaryColor : Colors.grey.shade300),
                  ),
                  child: PopupMenuButton<String?>(
                    icon: Icon(Icons.filter_list, color: _filterConversion != null ? primaryColor : Colors.black54),
                    tooltip: 'Filter by Conversion',
                    onSelected: (val) => setState(() => _filterConversion = val),
                    itemBuilder: (ctx) {
                      return [
                        const PopupMenuItem<String?>(
                          value: null,
                          child: Text('All Conversions'),
                        ),
                        ...dp.options.map((e) => PopupMenuItem<String?>(
                          value: e,
                          child: Text(e),
                        )),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Status'),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                for (final s in LeadStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: _filterStatus == s,
                      onSelected: (_) => setState(() => _filterStatus = s),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.loadHistory,
              child: filtered.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No leads in history.')),
                ],
              )
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final lead = filtered[i];
                  return LeadTile(
                    lead: lead,
                    selected: false,
                    onChanged: (_) {},
                    showCheckbox: false,
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
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all stored leads. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<LeadProvider>().clearHistory();
    }
  }
}