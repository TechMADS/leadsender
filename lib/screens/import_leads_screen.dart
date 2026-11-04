import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leadsender/theme/color.dart';
import 'package:provider/provider.dart';
import '../providers/lead_provider.dart';
import '../services/phone_number_extractor.dart';
import '../services/share_intent_service.dart';
import 'extracted_leads_screen.dart';

class ImportLeadsScreen extends StatefulWidget {
  const ImportLeadsScreen({super.key});

  @override
  State<ImportLeadsScreen> createState() => _ImportLeadsScreenState();
}

class _ImportLeadsScreenState extends State<ImportLeadsScreen> {
  final _controller = TextEditingController();
  final _extractor = PhoneNumberExtractor();
  bool _busy = false;

  static const _sample = '''Hi bro, here are today's leads:

9876543210
+91 9840123456

Interested shops:
9360123456, 9790012345

Contact Raj: (0413) 2234567
''';

  @override
  void initState() {
    super.initState();
    // Consume initial shared text if any.
    final shared = ShareIntentService.instance.consumeInitialText();
    if (shared != null) _controller.text = shared;
    // Listen for new shares while app is running.
    ShareIntentService.instance.stream.listen((text) {
      if (!mounted) return;
      setState(() => _controller.text = text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _controller.text += (data!.text ?? ''));
    }
  }

  Future<void> _extract() async {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      _snack('Please enter or paste some text first.');
      return;
    }
    setState(() => _busy = true);
    final result = _extractor.extract(text);
    await context.read<LeadProvider>().applyExtraction(result);
    setState(() => _busy = false);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExtractedLeadsScreen()),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Import Leads',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  labelText: 'Paste WhatsApp messages or phone numbers here',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Paste'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _controller.clear()),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _controller.text = _sample),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Sample'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _extract,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Extract Numbers'),
            ),
          ],
        ),
      ),
    );
  }
}
