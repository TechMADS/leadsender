import 'package:flutter/material.dart';
import '../models/lead.dart';

class LeadTile extends StatelessWidget {
  final Lead lead;
  final bool selected;
  final ValueChanged<bool?> onChanged;
  final bool showCheckbox;
  final VoidCallback? onTap;

  const LeadTile({
    super.key,
    required this.lead,
    required this.selected,
    required this.onChanged,
    this.showCheckbox = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // _conversionBadge(lead.conversionStatus),
        // const SizedBox(width: 6),
        Icon(
          _statusIcon(lead.status),
          color: _statusColor(lead.status),
        ),
      ],
    );

    final subtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detected: ${lead.originalNumber} • ${_statusLabel(lead.status)}'),
        if (lead.location != null && lead.location!.isNotEmpty)
          Text('📍 ${lead.location}'),
        if (lead.enquiry != null && lead.enquiry!.isNotEmpty)
          Text('📝 ${lead.enquiry}'),
      ],
    );

    final title = Text(
      (lead.name != null && lead.name!.isNotEmpty)
          ? '${lead.name} — ${lead.normalizedNumber}'
          : lead.normalizedNumber,
    );

    if (showCheckbox) {
      return CheckboxListTile(
        value: selected,
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
        secondary: trailing,
        activeColor: Colors.green,
      );
    }

    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _conversionBadge(String s) {
    Color color;
    if (s.toLowerCase() == 'converted') {
      color = Colors.green;
    } else if (s.toLowerCase() == 'wrong') {
      color = Colors.red;
    } else if (s.toLowerCase() == 'newlead') {
      color = Colors.blue;
    } else {
      color = Colors.purple; // Custom statuses
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(LeadStatus s) {
    switch (s) {
      case LeadStatus.pending:
        return 'Pending';
      case LeadStatus.opened:
        return 'Opened in WhatsApp';
      case LeadStatus.sent:
        return 'Marked Sent';
      case LeadStatus.skipped:
        return 'Skipped';
      case LeadStatus.failed:
        return 'Failed';
    }
  }

  IconData _statusIcon(LeadStatus s) {
    switch (s) {
      case LeadStatus.pending:
        return Icons.schedule;
      case LeadStatus.opened:
        return Icons.open_in_new;
      case LeadStatus.sent:
        return Icons.check_circle;
      case LeadStatus.skipped:
        return Icons.skip_next;
      case LeadStatus.failed:
        return Icons.error;
    }
  }

  Color? _statusColor(LeadStatus s) {
    switch (s) {
      case LeadStatus.sent:
        return Colors.green;
      case LeadStatus.failed:
        return Colors.red;
      case LeadStatus.skipped:
        return Colors.orange;
      default:
        return null;
    }
  }
}