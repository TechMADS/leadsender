import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lead.dart';

class LeadSheetService {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbx7V9KuyAsqO4LeBTkc4vgIbu50Nq1ft_0Vaq0F1y4ByzUcG7eZP0r7rkq0YXzy_Yho/exec';

  Future<List<Lead>> fetchAll() async {
    final res = await http.get(
      Uri.parse(_baseUrl),
      headers: {'User-Agent': 'LeadSender/1.0'},
    );
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is Map && data['error'] != null) {
      throw Exception(data['error']);
    }
    return (data as List)
        .map((e) => _rowToLead(e as Map<String, dynamic>))
        .toList();
  }

  // Future<String> addLead(Lead lead) async {
  //   final res = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'action': 'add',
  //       'lead': {
  //         'normalized_number': lead.normalizedNumber,
  //         'original_number': lead.originalNumber,
  //         'name': lead.name ?? '',
  //         'status': lead.status.name,
  //         'conversion_status': lead.conversionStatus, // Fixed: removed .name
  //         'location': lead.location ?? '',
  //         'enquiry': lead.enquiry ?? '',
  //         'imported_at': lead.importedAt.toIso8601String(),
  //         'last_processed_at': lead.lastProcessedAt?.toIso8601String() ?? '',
  //       },
  //     }),
  //   );
  //   final data = jsonDecode(res.body);
  //   if (data['error'] != null) throw Exception(data['error']);
  //   return data['id'] as String;
  // }

  Future<String> addLead(Lead lead) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'add',
        'lead': {
          'normalized_number': lead.normalizedNumber,
          'original_number': lead.originalNumber,
          'name': lead.name ?? '',
          'status': lead.status.name,
          'conversion_status': lead.conversionStatus,
          'location': lead.location ?? '',
          'enquiry': lead.enquiry ?? '',
          'site_status': lead.siteStatus ?? '', // NEW
          'source': lead.source ?? '',           // NEW
          'imported_at': lead.importedAt.toIso8601String(),
          'last_processed_at': lead.lastProcessedAt?.toIso8601String() ?? '',
        },
      }),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
    return data['id'] as String;
  }

  // Future<void> updateConversion(
  //     String id, {
  //       String? conversionStatus,
  //       String? location,
  //       String? enquiry,
  //       String? name,
  //     }) async {
  //   final res = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'action': 'updateConversion',
  //       'id': id,
  //       'conversionStatus': conversionStatus,
  //       'location': location,
  //       'enquiry': enquiry,
  //       'name': name,
  //     }),
  //   );
  //   final data = jsonDecode(res.body);
  //   if (data['error'] != null) throw Exception(data['error']);
  // }

  Future<void> updateConversion(
      String id, {
        String? conversionStatus,
        String? location,
        String? enquiry,
        String? name,
        String? siteStatus,
        String? source,
        String? status,
      }) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'updateConversion',
        'id': id,
        'conversionStatus': conversionStatus,
        'location': location,
        'enquiry': enquiry,
        'name': name,
        'siteStatus': siteStatus,
        'source': source,
        'status': status,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  // --- NEW METHODS FOR DROPDOWNS ---
  Future<List<String>> fetchDropdownOptions() async {
    final res = await http.get(Uri.parse('$_baseUrl?action=getDropdowns'));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (data is Map && data['error'] != null) throw Exception(data['error']);
    return (data as List).map((e) => e.toString()).toList();
  }

  // Future<void> addDropdownOption(String option) async {
  //   final res = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({'action': 'addDropdownOption', 'option': option}),
  //   );
  //   final data = jsonDecode(res.body);
  //   if (data['error'] != null) throw Exception(data['error']);
  // }

  Future<void> deleteLead(String id) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'delete', 'id': id}),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  Future<void> updateStatus(
      String id,
      String status, {
        String? lastProcessedAt,
      }) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'updateStatus',
        'id': id,
        'status': status,
        'lastProcessedAt': lastProcessedAt,
      }),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  // --- TEMPLATES ---
  Future<List<Map<String, dynamic>>> fetchTemplates() async {
    final res = await http.get(Uri.parse('$_baseUrl?action=getTemplates'));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (data is Map && data['error'] != null) throw Exception(data['error']);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addTemplate(String id, String name, String body) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'addTemplate',
        'template': {'id': id, 'name': name, 'body': body},
      }),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  // --- NEW DROPDOWNS ---
  Future<List<String>> fetchDropdown(String type) async {
    final res = await http.get(Uri.parse('$_baseUrl?action=get$type'));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(res.body);
    if (data is Map && data['error'] != null) throw Exception(data['error']);
    return (data as List).map((e) => e.toString()).toList();
  }

  Future<void> addDropdownOption(String type, String option) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'addDropdownOption', 'type': type, 'option': option}),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  Future<void> clearAll() async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'clear'}),
    );
    final data = jsonDecode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
  }

  Lead _rowToLead(Map<String, dynamic> m) {
    String? str(String key) {
      final v = m[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return Lead(
      sheetId: str('id'),
      normalizedNumber: str('normalized_number') ?? '',
      originalNumber: str('original_number') ?? '',
      name: str('name'),
      importedAt: DateTime.tryParse(str('imported_at') ?? '') ?? DateTime.now(),
      lastProcessedAt: DateTime.tryParse(str('last_processed_at') ?? ''),
      status: LeadStatus.values.firstWhere(
            (e) => e.name == str('status'),
        orElse: () => LeadStatus.pending,
      ),
      conversionStatus: str('conversion_status') ?? 'newLead',
      location: str('location'),
      enquiry: str('enquiry'),
      siteStatus: str('site_status'), // <-- ADDED
      source: str('source'),           // <-- ADDED
    );
  }

  // Lead _rowToLead(Map<String, dynamic> m) {
  //   // Helper to safely get a string, handling nulls and unexpected types
  //   String? str(String key) {
  //     final v = m[key];
  //     if (v == null) return null;
  //     final s = v.toString().trim();
  //     return s.isEmpty ? null : s;
  //   }
  //
  //   return Lead(
  //     sheetId: str('id'),
  //     normalizedNumber: str('normalized_number') ?? '',
  //     originalNumber: str('original_number') ?? '',
  //     name: str('name'),
  //     importedAt:
  //     DateTime.tryParse(str('imported_at') ?? '') ?? DateTime.now(),
  //     lastProcessedAt: DateTime.tryParse(str('last_processed_at') ?? ''),
  //     status: LeadStatus.values.firstWhere(
  //           (e) => e.name == str('status'),
  //       orElse: () => LeadStatus.pending,
  //     ),
  //     conversionStatus: str('conversion_status') ?? 'newLead', // Fixed: directly read as string
  //     location: str('location'),
  //     enquiry: str('enquiry'),
  //   );
  // }
}