import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message_template.dart';
import '../providers/template_provider.dart';
import '../theme/color.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TemplateProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Message Templates',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), ),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text('New Template', style: TextStyle(color: Colors.white),),
      ),
      body: tp.templates.isEmpty
          ? const Center(child: Text('No templates yet. Tap + to add one.'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tp.templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final t = tp.templates[i];
          return Card(
            child: ListTile(
              title: Row(
                children: [
                  Expanded(child: Text(t.name)),
                  if (t.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Default',
                          style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
              subtitle: Text(
                t.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openEditor(context, t),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    _openEditor(context, t);
                  } else if (v == 'default') {
                    await context
                        .read<TemplateProvider>()
                        .setDefault(t.id);
                  } else if (v == 'delete') {
                    final ok = await _confirmDelete(context, t.name);
                    if (ok == true && context.mounted) {
                      await context
                          .read<TemplateProvider>()
                          .delete(t.id);
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'default', child: Text('Set as Default')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete template?'),
          content: Text('Delete "$name"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

  void _openEditor(BuildContext context, MessageTemplate? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(existing: existing),
      ),
    );
  }
}

class TemplateEditorScreen extends StatefulWidget {
  final MessageTemplate? existing;
  const TemplateEditorScreen({super.key, this.existing});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _body;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _body = TextEditingController(text: widget.existing?.body ?? '');
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tp = context.read<TemplateProvider>();
    if (widget.existing == null) {
      final t = MessageTemplate(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        body: _body.text,
        isDefault: _isDefault || tp.templates.isEmpty,
      );
      await tp.add(t);
      if (t.isDefault) await tp.setDefault(t.id);
    } else {
      final t = widget.existing!.copyWith(
        name: _name.text.trim(),
        body: _body.text,
        isDefault: _isDefault,
      );
      await tp.update(t);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? 'New Template' : 'Edit Template', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: Colors.white),)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Template Name', fillColor: Colors.white),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                alignLabelWithHint: true,
                fillColor: Colors.white
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Placeholders: {shop_name}, {introduction}, {shop_address}, '
                  '{contact_number}, {catalogue_url}, {website_line}, '
                  '{lead_name}, {phone_number}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Use as default template'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}