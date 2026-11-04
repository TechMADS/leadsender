import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lead_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/color.dart';
import '../widgets/stat_card.dart';
import 'import_leads_screen.dart';
import 'lead_history_screen.dart';
import 'business_settings_screen.dart';
import 'message_preview_screen.dart';
import 'templates_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leads = context.watch<LeadProvider>();
    final settings = context.watch<SettingsProvider>();
    final stats = leads.stats;

    final totalLeads = leads.history.length;
    final sent = stats['sent'] ?? 0;
    final skipped = stats['skipped'] ?? 0;
    final pending = stats['pending'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          settings.profile.shopName.isEmpty
              ? 'Welcome 👋'
              : settings.profile.shopName,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: leads.loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: leads.loading ? null : leads.loadHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: leads.loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (leads.lastError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sync error: ${leads.lastError}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: leads.loadHistory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(label: 'Total Leads', value: '$totalLeads'),
                StatCard(label: 'Pending', value: '$pending'),
                StatCard(
                    label: 'Sent', value: '$sent', color: Colors.green),
                StatCard(
                    label: 'Skipped',
                    value: '$skipped',
                    color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportLeadsScreen()),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Leads'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeadHistoryScreen()),
              ),
              icon: const Icon(Icons.history),
              label: const Text('Lead History'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MessagePreviewScreen()),
              ),
              icon: const Icon(Icons.message),
              label: const Text('Message Template'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BusinessSettingsScreen()),
              ),
              icon: const Icon(Icons.settings),
              label: const Text('Business Settings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              ),
              icon: const Icon(Icons.article),
              label: const Text('Message Templates'),
            ),
          ],
        ),
      ),
    );
  }
}