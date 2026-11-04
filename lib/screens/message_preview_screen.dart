import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/message_template.dart';
import '../providers/settings_provider.dart';
import '../providers/template_provider.dart';
import '../services/message_template_service.dart';
import '../theme/color.dart';
import 'templates_screen.dart';

class MessagePreviewScreen extends StatelessWidget {
  const MessagePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsProvider>().profile;
    final tp = context.watch<TemplateProvider>();
    final templates = tp.templates;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Message Preview', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),),
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white,),
            tooltip: 'Manage Templates',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplatesScreen()),
            ),
          ),
        ],
      ),
      body: templates.isEmpty
          ? _EmptyState(
        onManage: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TemplatesScreen()),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length + 1, // +1 for footer tip
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == templates.length) {
            return const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '',
                style: TextStyle(fontSize: 12),
              ),
            );
          }
          final t = templates[i];
          return _TemplatePreviewCard(
            template: t,
            profile: profile,
            isSelected: tp.selected?.id == t.id,
          );
        },
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  final MessageTemplate template;
  final dynamic profile;
  final bool isSelected;

  const _TemplatePreviewCard({
    required this.template,
    required this.profile,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Render this specific template with a sample lead.
    final rendered = MessageTemplateService.renderBody(
      body: template.body,
      profile: profile,
      lead: MessageTemplateService.sampleLead(),
    );

    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header: name + badges ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (template.isDefault)
                  _Badge(
                    label: 'Default',
                    color: scheme.primaryContainer,
                    textColor: scheme.onPrimaryContainer,
                  ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  _Badge(
                    label: 'Selected',
                    color: scheme.secondaryContainer,
                    textColor: scheme.onSecondaryContainer,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Preview with sample recipient: Raj, +91 98765 43210',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),

            // ---- Message body preview ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                rendered,
                style: const TextStyle(height: 1.35),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Actions ----
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rendered));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preview copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
                const Spacer(),
                if (!isSelected)
                  FilledButton.tonal(
                    onPressed: () {
                      context.read<TemplateProvider>().select(template);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${template.name}" selected'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Use This'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: null,
                    child: const Text('In Use'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onManage;
  const _EmptyState({required this.onManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first template to see it previewed here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }
}