import 'package:flutter/foundation.dart';
import '../models/extraction_result.dart';
import '../models/lead.dart';
import '../services/lead_sheet_service.dart';

class LeadProvider extends ChangeNotifier {
  final LeadSheetService _sheet = LeadSheetService();

  final List<Lead> _currentBatch = [];
  final List<RejectedRow> _rejected = [];
  final List<ExtractedNumber> _ambiguous = [];
  int _duplicatesRemoved = 0;
  int _alreadyProcessed = 0;

  List<Lead> get batch => List.unmodifiable(_currentBatch);
  List<RejectedRow> get rejected => List.unmodifiable(_rejected);
  List<ExtractedNumber> get ambiguous => List.unmodifiable(_ambiguous);
  int get duplicatesRemoved => _duplicatesRemoved;
  int get alreadyProcessed => _alreadyProcessed;

  List<Lead> _history = [];
  List<Lead> get history => List.unmodifiable(_history);

  bool _loading = false;
  bool get loading => _loading;

  String? _lastError;
  String? get lastError => _lastError;

  Map<String, int> _stats = {};
  Map<String, int> get stats => _stats;

  void _recomputeStats() {
    final map = <String, int>{};
    for (final l in _history) {
      map[l.status.name] = (map[l.status.name] ?? 0) + 1;
    }
    _stats = map;
  }

  Future<void> loadHistory() async {
    _loading = true;
    notifyListeners();
    try {
      final rawHistory = await _sheet.fetchAll();

      // Deduplicate by normalizedNumber so the dashboard shows unique counts
      final Map<String, Lead> uniqueMap = {};
      for (final lead in rawHistory) {
        uniqueMap[lead.normalizedNumber] = lead;
      }
      _history = uniqueMap.values.toList();

      _recomputeStats();
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('loadHistory failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> applyExtraction(ExtractionResult result) async {
    _currentBatch.clear();
    _rejected.clear();
    _ambiguous.clear();
    _duplicatesRemoved = result.duplicatesRemoved;
    _alreadyProcessed = 0;
    _rejected.addAll(result.rejected.map((r) => RejectedRow(r.raw, r.reason)));
    _ambiguous.addAll(result.ambiguous);

    for (final n in result.valid) {
      Lead? existing;
      for (final h in _history) {
        if (h.normalizedNumber == n.normalized) {
          existing = h;
          break;
        }
      }
      final lead = Lead(
        sheetId: existing?.sheetId,
        normalizedNumber: n.normalized,
        originalNumber: n.original,
        name: n.name ?? existing?.name,
        location: n.location ?? existing?.location,
        enquiry: n.enquiry ?? existing?.enquiry,
        importedAt: existing?.importedAt ?? DateTime.now(),
        lastProcessedAt: existing?.lastProcessedAt,
        status: existing?.status ?? LeadStatus.pending,
        conversionStatus: existing?.conversionStatus ?? 'newLead', // ← Updated to String
      );
      if (existing != null && existing.status == LeadStatus.sent) {
        _alreadyProcessed++;
      }
      _currentBatch.add(lead);
    }
    notifyListeners();
  }

  void toggleSelection(int index, bool selected) {
    notifyListeners();
  }

  void addManual({
    required String normalized,
    required String original,
    String? name,
  }) {
    _currentBatch.add(Lead(
      normalizedNumber: normalized,
      originalNumber: original,
      name: name,
      importedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void removeIndices(Set<int> indices) {
    final sorted = indices.toList()..sort((a, b) => b.compareTo(a));
    for (final i in sorted) {
      if (i >= 0 && i < _currentBatch.length) {
        _currentBatch.removeAt(i);
      }
    }
    notifyListeners();
  }

  Future<void> persistBatch() async {
    for (final lead in _currentBatch) {
      if (lead.sheetId != null) continue;
      try {
        final id = await _sheet.addLead(lead);
        lead.sheetId = id;
      } catch (e) {
        debugPrint('persistBatch failed for ${lead.normalizedNumber}: $e');
      }
    }
    await loadHistory();
  }

  Future<void> updateConversion(
      Lead lead, {
        String? conversionStatus,
        String? location,
        String? enquiry,
        String? name,
      }) async {
    if (conversionStatus != null) lead.conversionStatus = conversionStatus;
    if (location != null) lead.location = location;
    if (enquiry != null) lead.enquiry = enquiry;
    if (name != null) lead.name = name; // Wait, name is final in Lead!
    // Actually, let's fix Lead model to make 'name' mutable like location/enquiry.

    try {
      if (lead.sheetId != null) {
        await _sheet.updateConversion(
          lead.sheetId!,
          conversionStatus: lead.conversionStatus,
          location: lead.location ?? '',
          enquiry: lead.enquiry ?? '',
          name: lead.name ?? '',
        );
      } else {
        final id = await _sheet.addLead(lead);
        lead.sheetId = id;
      }
    } catch (e) {
      debugPrint('updateConversion failed: $e');
      _lastError = e.toString();
    }

    await loadHistory();
  }

  Future<void> updateLeadStatus(Lead lead, LeadStatus status) async {
    lead.status = status;
    lead.lastProcessedAt = DateTime.now();

    try {
      if (lead.sheetId == null) {
        final id = await _sheet.addLead(lead);
        lead.sheetId = id;
      } else {
        await _sheet.updateStatus(
          lead.sheetId!,
          status.name,
          lastProcessedAt: lead.lastProcessedAt!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('updateLeadStatus failed: $e');
      _lastError = e.toString();
    }

    await loadHistory();
  }

  Future<void> addLead(Lead lead) async {
    try {
      final id = await _sheet.addLead(lead);
      lead.sheetId = id;
      _history.insert(0, lead);
      _recomputeStats();
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> deleteLead(Lead lead) async {
    try {
      if (lead.sheetId != null) {
        await _sheet.deleteLead(lead.sheetId!);
      }
      _history.removeWhere((h) => h.normalizedNumber == lead.normalizedNumber);
      _recomputeStats();
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  // Future<void> deleteLead(Lead lead) async {
  //   try {
  //     if (lead.sheetId != null) {
  //       await _sheet.deleteLead(lead.sheetId!);
  //     }
  //     _history.removeWhere((h) => h.normalizedNumber == lead.normalizedNumber);
  //     _recomputeStats();
  //   } catch (e) {
  //     _lastError = e.toString();
  //   }
  //   notifyListeners();
  // }

  Future<void> deleteBySheetId(String sheetId) async {
    try {
      await _sheet.deleteLead(sheetId);
      _history.removeWhere((h) => h.sheetId == sheetId);
      _recomputeStats();
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> clearHistory() async {
    try {
      await _sheet.clearAll();
      _history = [];
      _stats = {};
      _lastError = null;
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }
}

class RejectedRow {
  final String raw;
  final String reason;
  RejectedRow(this.raw, this.reason);
}


// import 'package:flutter/foundation.dart';
// import '../models/extraction_result.dart';
// import '../models/lead.dart';
// import '../services/lead_database_service.dart';
//
// class LeadProvider extends ChangeNotifier {
//   final LeadDatabaseService _db;
//   LeadProvider(this._db);
//
//   final List<Lead> _currentBatch = [];
//   final List<RejectedRow> _rejected = [];
//   final List<ExtractedNumber> _ambiguous = [];
//   int _duplicatesRemoved = 0;
//   int _alreadyProcessed = 0;
//
//   List<Lead> get batch => List.unmodifiable(_currentBatch);
//   List<RejectedRow> get rejected => List.unmodifiable(_rejected);
//   List<ExtractedNumber> get ambiguous => List.unmodifiable(_ambiguous);
//   int get duplicatesRemoved => _duplicatesRemoved;
//   int get alreadyProcessed => _alreadyProcessed;
//
//   Map<String, int> _stats = {};
//   Map<String, int> get stats => _stats;
//
//   List<Lead> _history = [];
//   List<Lead> get history => List.unmodifiable(_history);
//
//   Future<void> loadHistory() async {
//     _history = await _db.all();
//     _stats = await _db.stats();
//     notifyListeners();
//   }
//
//   Future<void> applyExtraction(ExtractionResult result) async {
//     _currentBatch.clear();
//     _rejected.clear();
//     _ambiguous.clear();
//     _duplicatesRemoved = result.duplicatesRemoved;
//     _alreadyProcessed = 0;
//     _rejected.addAll(result.rejected.map((r) => RejectedRow(r.raw, r.reason)));
//     _ambiguous.addAll(result.ambiguous);
//
//     for (final n in result.valid) {
//       final existing = await _db.findByNumber(n.normalized);
//       final lead = Lead(
//         normalizedNumber: n.normalized,
//         originalNumber: n.original,
//         importedAt: DateTime.now(),
//         status: existing?.status ?? LeadStatus.pending,
//         lastProcessedAt: existing?.lastProcessedAt,
//       );
//       if (existing != null && existing.status == LeadStatus.sent) {
//         _alreadyProcessed++;
//       }
//       _currentBatch.add(lead);
//     }
//     notifyListeners();
//   }
//
//   void toggleSelection(int index, bool selected) {
//     // Selection is tracked by the screen locally; this is a placeholder for
//     // batch-level state if needed.
//     notifyListeners();
//   }
//
//   void addManual({required String normalized, required String original, String? name}) {
//     _currentBatch.add(Lead(
//       normalizedNumber: normalized,
//       originalNumber: original,
//       name: name,
//       importedAt: DateTime.now(),
//     ));
//     notifyListeners();
//   }
//
//   void removeIndices(Set<int> indices) {
//     final sorted = indices.toList()..sort((a, b) => b.compareTo(a));
//     for (final i in sorted) {
//       _currentBatch.removeAt(i);
//     }
//     notifyListeners();
//   }
//
//   Future<void> persistBatch() async {
//     for (final lead in _currentBatch) {
//       final existing = await _db.findByNumber(lead.normalizedNumber);
//       if (existing == null) {
//         final id = await _db.insert(lead);
//         lead.id = id;
//       }
//     }
//     await loadHistory();
//   }
//
//   Future<void> updateLeadStatus(Lead lead, LeadStatus status) async {
//     lead.status = status;
//     lead.lastProcessedAt = DateTime.now();
//     if (lead.id != null) {
//       await _db.update(lead);
//     } else {
//       final id = await _db.insert(lead);
//       lead.id = id;
//     }
//     notifyListeners();
//   }
//
//   Future<void> clearHistory() async {
//     await _db.clearAll();
//     _history = [];
//     _stats = {};
//     notifyListeners();
//   }
// }
//
// class RejectedRow {
//   final String raw;
//   final String reason;
//   RejectedRow(this.raw, this.reason);
// }