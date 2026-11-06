enum LeadStatus { pending, opened, sent, skipped, failed }

class Lead {
  int? id;
  String? sheetId;
  final String normalizedNumber;
  final String originalNumber;
   String? name;
  final DateTime importedAt;
  DateTime? lastProcessedAt;
  LeadStatus status;
  String conversionStatus; // Changed from enum to String
  String? location;
  String? enquiry;
  String? notes;
  String? siteStatus;
  String? source;

  Lead({
    this.id,
    this.sheetId,
    required this.normalizedNumber,
    required this.originalNumber,
    this.name,
    required this.importedAt,
    this.lastProcessedAt,
    this.status = LeadStatus.pending,
    this.conversionStatus = 'newLead',
    this.location,
    this.enquiry,
    this.notes,
    this.siteStatus, // NEW
    this.source,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'sheetId': sheetId,
    'normalized_number': normalizedNumber,
    'original_number': originalNumber,
    'name': name,
    'imported_at': importedAt.toIso8601String(),
    'last_processed_at': lastProcessedAt?.toIso8601String(),
    'status': status.name,
    'conversion_status': conversionStatus,
    'location': location,
    'enquiry': enquiry,
    'notes': notes,
    'site_status': siteStatus,
    'source': source,
  };

  factory Lead.fromMap(Map<String, Object?> m) => Lead(
    id: m['id'] as int?,
    sheetId: m['sheetId'] as String?,
    normalizedNumber: (m['normalized_number'] as String?) ?? '',
    originalNumber: (m['original_number'] as String?) ?? '',
    name: m['name'] as String?,
    importedAt: DateTime.tryParse((m['imported_at'] as String?) ?? '') ?? DateTime.now(),
    lastProcessedAt: (m['last_processed_at'] as String?)?.isNotEmpty == true
        ? DateTime.tryParse(m['last_processed_at'] as String)
        : null,
    status: LeadStatus.values.firstWhere(
          (e) => e.name == m['status'],
      orElse: () => LeadStatus.pending,
    ),
    conversionStatus: (m['conversion_status'] as String?) ?? 'newLead',
    location: m['location'] as String?,
    enquiry: m['enquiry'] as String?,
    notes: m['notes'] as String?,
    siteStatus: m['site_status'] as String?,
    source: m['source'] as String?,
  );
}

// enum LeadStatus { pending, opened, sent, skipped, failed }
//
// enum LeadConversionStatus { newLead, converted, wrong }
//
// class Lead {
//   int? id;
//   String? sheetId;
//   final String normalizedNumber;
//   final String originalNumber;
//   String? name;
//   final DateTime importedAt;
//   DateTime? lastProcessedAt;
//   LeadStatus status;
//   LeadConversionStatus conversionStatus;
//   String? location;
//   String? enquiry;
//   String? notes;
//
//   Lead({
//     this.id,
//     this.sheetId,
//     required this.normalizedNumber,
//     required this.originalNumber,
//     this.name,
//     required this.importedAt,
//     this.lastProcessedAt,
//     this.status = LeadStatus.pending,
//     this.conversionStatus = LeadConversionStatus.newLead,
//     this.location,
//     this.enquiry,
//     this.notes,
//   });
//
//   Map<String, Object?> toMap() => {
//     'id': id,
//     'sheetId': sheetId,
//     'normalized_number': normalizedNumber,
//     'original_number': originalNumber,
//     'name': name,
//     'imported_at': importedAt.toIso8601String(),
//     'last_processed_at': lastProcessedAt?.toIso8601String(),
//     'status': status.name,
//     'conversion_status': conversionStatus.name,
//     'location': location,
//     'enquiry': enquiry,
//     'notes': notes,
//   };
//
//   factory Lead.fromMap(Map<String, Object?> m) => Lead(
//     id: m['id'] as int?,
//     sheetId: m['sheetId'] as String?,
//     normalizedNumber: (m['normalized_number'] as String?) ?? '',
//     originalNumber: (m['original_number'] as String?) ?? '',
//     name: m['name'] as String?,
//     importedAt: DateTime.tryParse((m['imported_at'] as String?) ?? '') ??
//         DateTime.now(),
//     lastProcessedAt: (m['last_processed_at'] as String?)?.isNotEmpty == true
//         ? DateTime.tryParse(m['last_processed_at'] as String)
//         : null,
//     status: LeadStatus.values.firstWhere(
//           (e) => e.name == m['status'],
//       orElse: () => LeadStatus.pending,
//     ),
//     conversionStatus: LeadConversionStatus.values.firstWhere(
//           (e) => e.name == (m['conversion_status'] ?? 'newLead'),
//       orElse: () => LeadConversionStatus.newLead,
//     ),
//     location: m['location'] as String?,
//     enquiry: m['enquiry'] as String?,
//     notes: m['notes'] as String?,
//   );
// }
