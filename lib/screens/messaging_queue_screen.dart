import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/template_provider.dart';
import '../services/message_template_service.dart';
import '../services/whatsapp_launcher.dart';
import '../theme/color.dart';
import 'templates_screen.dart';

class MessagingQueueScreen extends StatefulWidget {
  final List<Lead> leads;
  const MessagingQueueScreen({super.key, required this.leads});

  @override
  State<MessagingQueueScreen> createState() => _MessagingQueueScreenState();
}

class _MessagingQueueScreenState extends State<MessagingQueueScreen> {
  int _index = 0;
  bool _paused = false;

  Lead get _current => widget.leads[_index];
  bool get _hasNext => _index < widget.leads.length - 1;
  bool get _hasPrev => _index > 0;

  Future<void> _open() async {
    final profile = context.read<SettingsProvider>().profile;
    final templateProvider = context.read<TemplateProvider>();

    // Use the selected template, falling back to default, then to the
    // profile template for backward compatibility.
    final templateBody =
        templateProvider.selected?.body ??
            templateProvider.defaultTemplate?.body ??
            profile.template;

    final effectiveProfile = profile.copyWith(template: templateBody);

    final message = MessageTemplateService.render(
      profile: effectiveProfile,
      lead: _current,
    );

    final ok = await WhatsAppLauncher.openChat(
      e164Number: _current.normalizedNumber,
      message: message,
    );
    if (!mounted) return;
    if (ok) {
      await context
          .read<LeadProvider>()
          .updateLeadStatus(_current, LeadStatus.opened);
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Is it installed?'),
        ),
      );
    }
  }

  Future<void> _setStatus(LeadStatus s) async {
    await context.read<LeadProvider>().updateLeadStatus(_current, s);
    if (!mounted) return;
    setState(() {});
    if (_hasNext) _next();
  }

  void _next() {
    if (_hasNext) setState(() => _index++);
  }

  void _prev() {
    if (_hasPrev) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    final lead = _current;
    final tp = context.watch<TemplateProvider>();
    final selectedName = tp.selected?.name ?? 'None';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Queue ${_index + 1} / ${widget.leads.length}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          // IconButton(
          //   icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: Colors.white,),
          //   onPressed: () => setState(() => _paused = !_paused),
          //   tooltip: _paused ? 'Resume' : 'Pause',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.close, color: Colors.white,),
          //   onPressed: () => Navigator.pop(context),
          //   tooltip: 'Stop Queue',
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name?.isNotEmpty == true
                          ? lead.name!
                          : 'Recipient',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lead.normalizedNumber,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Status: ${lead.status.name}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- TEMPLATE PICKER ----------
            Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Message Template'),
                subtitle: Text(selectedName),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showTemplatePicker,
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: _paused ? null : _open,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open WhatsApp with Message'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _paused ? null : () => _setStatus(LeadStatus.sent),
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Mark as Sent', style: TextStyle(color: Colors.black),),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _paused ? null : () => _setStatus(LeadStatus.skipped),
              icon: const Icon(Icons.skip_next, color: Colors.green),
              label: const Text('Skip Lead', style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _paused ? null : () => _setStatus(LeadStatus.failed),
              icon: const Icon(Icons.error_outline, color: Colors.green,),
              label: const Text('Mark as Failed', style: TextStyle(color: Colors.black)),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _hasPrev ? _prev : null,
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Previous', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _hasNext ? _next : null,
                    style: FilledButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text('Next Lead'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplatePicker() {
    final tp = context.read<TemplateProvider>();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Choose Template',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in tp.templates)
                    RadioListTile<String>(
                      value: t.id,
                      groupValue: tp.selected?.id,
                      title: Text(t.name),
                      subtitle: Text(
                        t.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onChanged: (_) {
                        tp.select(t);
                        Navigator.pop(context);
                      },
                      activeColor: Colors.green,
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Manage Templates'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TemplatesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../models/lead.dart';
// import '../providers/lead_provider.dart';
// import '../providers/settings_provider.dart';
// import '../services/message_template_service.dart';
// import '../services/whatsapp_launcher.dart';
//
// class MessagingQueueScreen extends StatefulWidget {
//   final List<Lead> leads;
//   const MessagingQueueScreen({super.key, required this.leads});
//
//   @override
//   State<MessagingQueueScreen> createState() => _MessagingQueueScreenState();
// }
//
// class _MessagingQueueScreenState extends State<MessagingQueueScreen> {
//   int _index = 0;
//   bool _paused = false;
//
//   Lead get _current => widget.leads[_index];
//   bool get _hasNext => _index < widget.leads.length - 1;
//   bool get _hasPrev => _index > 0;
//
//   Future<void> _open() async {
//     final profile = context.read<SettingsProvider>().profile;
//     final message =
//     MessageTemplateService.render(profile: profile, lead: _current);
//     final ok = await WhatsAppLauncher.openChat(
//       e164Number: _current.normalizedNumber,
//       message: message,
//     );
//     if (!mounted) return;
//     if (ok) {
//       await context
//           .read<LeadProvider>()
//           .updateLeadStatus(_current, LeadStatus.opened);
//       setState(() {});
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Could not open WhatsApp. Is it installed?'),
//         ),
//       );
//     }
//   }
//
//   Future<void> _setStatus(LeadStatus s) async {
//     await context.read<LeadProvider>().updateLeadStatus(_current, s);
//     if (!mounted) return;
//     setState(() {});
//     if (_hasNext) _next();
//   }
//
//   void _next() {
//     if (_hasNext) setState(() => _index++);
//   }
//
//   void _prev() {
//     if (_hasPrev) setState(() => _index--);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final lead = _current;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Queue ${_index + 1} / ${widget.leads.length}'),
//         actions: [
//           IconButton(
//             icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
//             onPressed: () => setState(() => _paused = !_paused),
//             tooltip: _paused ? 'Resume' : 'Pause',
//           ),
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//             tooltip: 'Stop Queue',
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       lead.name?.isNotEmpty == true
//                           ? lead.name!
//                           : 'Recipient',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       lead.normalizedNumber,
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 8),
//                     Text('Status: ${lead.status.name}'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             FilledButton.icon(
//               onPressed: _paused ? null : _open,
//               icon: const Icon(Icons.open_in_new),
//               label: const Text('Open WhatsApp with Message'),
//             ),
//             const SizedBox(height: 12),
//             OutlinedButton.icon(
//               onPressed:
//               _paused ? null : () => _setStatus(LeadStatus.sent),
//               icon: const Icon(Icons.check),
//               label: const Text('Mark as Sent'),
//             ),
//             const SizedBox(height: 12),
//             OutlinedButton.icon(
//               onPressed:
//               _paused ? null : () => _setStatus(LeadStatus.skipped),
//               icon: const Icon(Icons.skip_next),
//               label: const Text('Skip Lead'),
//             ),
//             const SizedBox(height: 12),
//             OutlinedButton.icon(
//               onPressed:
//               _paused ? null : () => _setStatus(LeadStatus.failed),
//               icon: const Icon(Icons.error_outline),
//               label: const Text('Mark as Failed'),
//             ),
//             const Spacer(),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: _hasPrev ? _prev : null,
//                     child: const Text('Previous'),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: FilledButton(
//                     onPressed: _hasNext ? _next : null,
//                     child: const Text('Next Lead'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }