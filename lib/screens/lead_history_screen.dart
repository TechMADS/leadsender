import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/lead_provider.dart';
import '../providers/dropdown_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/template_provider.dart';
import '../services/message_template_service.dart';
import '../services/whatsapp_launcher.dart';
import '../theme/color.dart';
import '../widgets/lead_tile.dart';
import '../widgets/edit_lead_dialog.dart';
import 'add_lead_screen.dart';

class LeadHistoryScreen extends StatefulWidget {
  const LeadHistoryScreen({super.key});

  @override
  State<LeadHistoryScreen> createState() => _LeadHistoryScreenState();
}

class _LeadHistoryScreenState extends State<LeadHistoryScreen> {
  String _query = '';
  LeadStatus? _filterStatus;

  // One single string to hold whatever filter is selected
  String? _globalFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<DropdownProvider>().loadOptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeadProvider>();
    final dp = context.watch<DropdownProvider>();

    // 1. Gather all unique names from the history
    final uniqueSites = provider.history.map((e) => e.siteStatus ?? '').where((e) => e.isNotEmpty).toSet();
    final uniqueSources = provider.history.map((e) => e.source ?? '').where((e) => e.isNotEmpty).toSet();

    // 2. Combine everything into one big list for the filter menu
    final allFilterOptions = <String>{
      ...dp.options,       // Conversions
      ...uniqueSites,      // Site Statuses
      ...uniqueSources,    // Sources
    }.toList()..sort();

    final filtered = provider.history.where((l) {
      final q = _query.toLowerCase();
      final matches = q.isEmpty ||
          l.normalizedNumber.contains(q) ||
          (l.name ?? '').toLowerCase().contains(q) ||
          (l.location ?? '').toLowerCase().contains(q) ||
          (l.enquiry ?? '').toLowerCase().contains(q);

      final statusOk = _filterStatus == null || l.status == _filterStatus;

      // 3. Check if the selected global filter matches ANY of the fields
      final globalFilterOk = _globalFilter == null ||
          l.conversionStatus == _globalFilter ||
          l.siteStatus == _globalFilter ||
          l.source == _globalFilter;

      return matches && statusOk && globalFilterOk;
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddLeadScreen())
            ),
          ),
          IconButton(
            icon: provider.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: provider.loading ? null : provider.loadHistory,
          ),
          // IconButton(
          //   icon: const Icon(Icons.delete_sweep, color: Colors.white),
          //   onPressed: _confirmClear,
          // ),
        ],
      ),
      body: Column(
        children: [
          // --- Search & SINGLE Filter Button ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by number, name, location',
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
                  ),
                ),
                const SizedBox(width: 8),

                // SINGLE FILTER BUTTON
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: _globalFilter != null ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _globalFilter != null ? primaryColor : Colors.grey.shade300),
                  ),
                  child: PopupMenuButton<String?>(
                    color: Colors.white,
                    icon: Icon(
                        Icons.filter_list,
                        color: _globalFilter != null ? primaryColor : Colors.black54
                    ),
                    tooltip: 'Filter',
                    onSelected: (val) => setState(() => _globalFilter = val),
                    itemBuilder: (ctx) {
                      return [
                        const PopupMenuItem<String?>(
                          value: null,
                          child: Text('All (Clear Filter)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuDivider(),
                        // Generates the list of everything combined
                        ...allFilterOptions.map((e) => PopupMenuItem<String?>(
                            value: e,
                            child: Text(e)
                        )),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Indicator (Optional but helpful)
          if (_globalFilter != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
              child: Row(
                children: [
                  Chip(
                    label: Text('Filtering: $_globalFilter'),
                    onDeleted: () => setState(() => _globalFilter = null),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: primaryColor.withOpacity(0.1),
                  ),
                ],
              ),
            ),

          // --- Status Chips ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label:  Text('All Status', style: TextStyle(color: _filterStatus == null? Colors.white: Colors.black),),
                  selected: _filterStatus == null,
                  onSelected: (_) => setState(() => _filterStatus = null),
                  backgroundColor: Colors.white,
                  selectedColor: primaryColor,
                  checkmarkColor:Colors.white,
                ),
                const SizedBox(width: 8),
                for (final s in LeadStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      backgroundColor: Colors.white,
                      label: Text(s.name,style: TextStyle(color: _filterStatus == s? Colors.white: Colors.black)),
                      selected: _filterStatus == s,
                      onSelected: (_) => setState(() => _filterStatus = s),
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // --- List ---
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
                      final sendNow = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(lead.name ?? lead.normalizedNumber),
                          content: const Text('Do you want to message this lead on WhatsApp?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit Details', style: TextStyle(color: Colors.blue),)),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Open WhatsApp'),
                              style: FilledButton.styleFrom(backgroundColor: primaryColor),
                            ),
                          ],
                        ),
                      );

                      if (sendNow == true) {
                        final profile = context.read<SettingsProvider>().profile;
                        final template = context.read<TemplateProvider>().selected?.body ?? profile.template;
                        final msg = MessageTemplateService.renderBody(body: template, profile: profile, lead: lead);
                        await WhatsAppLauncher.openChat(e164Number: lead.normalizedNumber, message: msg);
                      }
                      else if (sendNow == false) {
                        final result = await showDialog<Map<String, Object?>>(
                          context: context,
                          builder: (_) => EditLeadDialog(lead: lead),
                        );
                        if (result != null && context.mounted) {
                          await context.read<LeadProvider>().updateConversion(
                            lead,
                            conversionStatus: result['conversionStatus'] as String?,
                            siteStatus: result['siteStatus'] as String?,
                            source: result['source'] as String?,
                            status: result['status'] as LeadStatus?,
                            name: result['name'] as String?,
                            location: result['location'] as String?,
                            enquiry: result['enquiry'] as String?,
                          );
                        }
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
        content: const Text('This will permanently delete all stored leads. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<LeadProvider>().clearHistory();
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/lead.dart';
// import '../providers/lead_provider.dart';
// import '../providers/dropdown_provider.dart';
// import '../providers/settings_provider.dart';
// import '../providers/template_provider.dart';
// import '../services/message_template_service.dart';
// import '../services/whatsapp_launcher.dart';
// import '../theme/color.dart';
// import '../widgets/lead_tile.dart';
// import '../widgets/edit_lead_dialog.dart';
// import 'add_lead_screen.dart';
//
// class LeadHistoryScreen extends StatefulWidget {
//   const LeadHistoryScreen({super.key});
//
//   @override
//   State<LeadHistoryScreen> createState() => _LeadHistoryScreenState();
// }
//
// class _LeadHistoryScreenState extends State<LeadHistoryScreen> {
//   String _query = '';
//   LeadStatus? _filterStatus;
//   String? _filterConversion;
//   String? _filterSite;
//   String? _filterSource;
//
//   List<String> _siteOpts = [];
//   List<String> _sourceOpts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       context.read<DropdownProvider>().loadOptions();
//       // We can reuse the provider or fetch directly from service for the others
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<LeadProvider>();
//     final dp = context.watch<DropdownProvider>();
//
//     // Extract unique site/source from current history for filtering (fallback)
//     final uniqueSites = provider.history.map((e) => e.siteStatus ?? '').where((e) => e.isNotEmpty).toSet().toList();
//     final uniqueSources = provider.history.map((e) => e.source ?? '').where((e) => e.isNotEmpty).toSet().toList();
//
//     final filtered = provider.history.where((l) {
//       final q = _query.toLowerCase();
//       final matches = q.isEmpty ||
//           l.normalizedNumber.contains(q) ||
//           (l.name ?? '').toLowerCase().contains(q) ||
//           (l.location ?? '').toLowerCase().contains(q) ||
//           (l.enquiry ?? '').toLowerCase().contains(q);
//
//       final statusOk = _filterStatus == null || l.status == _filterStatus;
//       final convOk = _filterConversion == null || l.conversionStatus == _filterConversion;
//       final siteOk = _filterSite == null || l.siteStatus == _filterSite;
//       final sourceOk = _filterSource == null || l.source == _filterSource;
//
//       return matches && statusOk && convOk && siteOk && sourceOk;
//     }).toList();
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Lead History',
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//         ),
//         backgroundColor: primaryColor,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add, color: Colors.white),
//             onPressed: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const AddLeadScreen())
//             ),
//           ),
//           IconButton(
//             icon: provider.loading
//                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                 : const Icon(Icons.refresh, color: Colors.white),
//             onPressed: provider.loading ? null : provider.loadHistory,
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_sweep, color: Colors.white),
//             onPressed: _confirmClear,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // --- Search & Filters ---
//           Padding(
//             padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         onChanged: (v) => setState(() => _query = v),
//                         decoration: const InputDecoration(
//                           fillColor: Colors.white,
//                           prefixIcon: Icon(Icons.search),
//                           hintText: 'Search by number, name, location',
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     // Conversion Filter
//                     _buildPopupFilter('Conversion', _filterConversion, dp.options, (val) {
//                       setState(() => _filterConversion = val);
//                     }),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 // Additional Filters (Site & Source)
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _buildPopupFilter('Site Status', _filterSite, uniqueSites, (val) {
//                         setState(() => _filterSite = val);
//                       }),
//                       const SizedBox(width: 8),
//                       _buildPopupFilter('Source', _filterSource, uniqueSources, (val) {
//                         setState(() => _filterSource = val);
//                       }),
//                       const SizedBox(width: 8),
//                       // Clear Filters
//                       if (_filterConversion != null || _filterSite != null || _filterSource != null)
//                         ActionChip(
//                           label: const Text('Clear'),
//                           onPressed: () => setState(() {
//                             _filterConversion = null;
//                             _filterSite = null;
//                             _filterSource = null;
//                           }),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // --- Status Chips ---
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 FilterChip(
//                   label: const Text('All Status'),
//                   selected: _filterStatus == null,
//                   onSelected: (_) => setState(() => _filterStatus = null),
//                 ),
//                 const SizedBox(width: 8),
//                 for (final s in LeadStatus.values)
//                   Padding(
//                     padding: const EdgeInsets.only(right: 8),
//                     child: FilterChip(
//                       label: Text(s.name),
//                       selected: _filterStatus == s,
//                       onSelected: (_) => setState(() => _filterStatus = s),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 4),
//
//           // --- List ---
//           Expanded(
//             child: RefreshIndicator(
//               onRefresh: provider.loadHistory,
//               child: filtered.isEmpty
//                   ? ListView(
//                 children: const [
//                   SizedBox(height: 200),
//                   Center(child: Text('No leads in history.')),
//                 ],
//               )
//                   : ListView.builder(
//                 itemCount: filtered.length,
//                 itemBuilder: (_, i) {
//                   final lead = filtered[i];
//                   return LeadTile(
//                     lead: lead,
//                     selected: false,
//                     onChanged: (_) {},
//                     showCheckbox: false,
//                     onTap: () async {
//                       final sendNow = await showDialog<bool>(
//                         context: context,
//                         builder: (ctx) => AlertDialog(
//                           title: Text(lead.name ?? lead.normalizedNumber),
//                           content: const Text('Do you want to message this lead on WhatsApp?'),
//                           actions: [
//                             TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Edit Details')),
//                             FilledButton(
//                                 onPressed: () => Navigator.pop(ctx, true),
//                                 child: const Text('Open WhatsApp')
//                             ),
//                           ],
//                         ),
//                       );
//
//                       if (sendNow == true) {
//                         final profile = context.read<SettingsProvider>().profile;
//                         final template = context.read<TemplateProvider>().selected?.body ?? profile.template;
//                         final msg = MessageTemplateService.renderBody(body: template, profile: profile, lead: lead);
//                         await WhatsAppLauncher.openChat(e164Number: lead.normalizedNumber, message: msg);
//                       } else if (sendNow == false) {
//                         final result = await showDialog<Map<String, Object?>>(
//                           context: context,
//                           builder: (_) => EditLeadDialog(lead: lead),
//                         );
//                         if (result != null && context.mounted) {
//                           await context.read<LeadProvider>().updateConversion(
//                             lead,
//                             conversionStatus: result['conversionStatus'] as String?,
//                             siteStatus: result['siteStatus'] as String?,
//                             source: result['source'] as String?,
//                             status: result['status'] as LeadStatus?,
//                             name: result['name'] as String?,
//                             location: result['location'] as String?,
//                             enquiry: result['enquiry'] as String?,
//                           );
//                         }
//                       }
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPopupFilter(String hint, String? currentVal, List<String> options, Function(String?) onSelected) {
//     return Container(
//       height: 48,
//       decoration: BoxDecoration(
//         color: currentVal != null ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: currentVal != null ? primaryColor : Colors.grey.shade300),
//       ),
//       child: PopupMenuButton<String?>(
//         icon: Icon(Icons.filter_list, color: currentVal != null ? primaryColor : Colors.black54),
//         tooltip: 'Filter by $hint',
//         onSelected: onSelected,
//         itemBuilder: (ctx) {
//           return [
//             PopupMenuItem<String?>(
//               value: null,
//               child: Text('All $hint'),
//             ),
//             ...options.map((e) => PopupMenuItem<String?>(value: e, child: Text(e))),
//           ];
//         },
//       ),
//     );
//   }
//
//   Future<void> _confirmClear() async {
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Clear History?'),
//         content: const Text('This will permanently delete all stored leads. This cannot be undone.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
//         ],
//       ),
//     );
//     if (ok == true && mounted) {
//       await context.read<LeadProvider>().clearHistory();
//     }
//   }
// }

