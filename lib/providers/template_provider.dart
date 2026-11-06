import 'package:flutter/foundation.dart';
import '../models/message_template.dart';
import '../services/lead_sheet_service.dart';
import '../services/template_service.dart';

class TemplateProvider extends ChangeNotifier {
  // 1. Declare the services
  final TemplateService _localService = TemplateService();
  final LeadSheetService _sheetService = LeadSheetService();

  List<MessageTemplate> _templates = [];
  MessageTemplate? _selected;
  bool _loaded = false;

  List<MessageTemplate> get templates => List.unmodifiable(_templates);
  MessageTemplate? get selected => _selected;
  bool get loaded => _loaded;

  MessageTemplate? get defaultTemplate =>
      _templates.isEmpty ? null : _templates.firstWhere(
            (t) => t.isDefault, orElse: () => _templates.first,
      );

  Future<void> load() async {
    // 1. Load instantly from local storage (SharedPreferences) so the UI is fast
    _templates = await _localService.load();
    _selected = defaultTemplate;
    _loaded = true;
    notifyListeners();

    // 2. Fetch latest from Google Sheet in the background
    try {
      final remote = await _sheetService.fetchTemplates();
      _templates = remote.map((e) => MessageTemplate(
          id: e['id'],
          name: e['name'],
          body: e['body']
      )).toList();

      if (_templates.isEmpty) {
        // If the sheet is empty, fall back to the local defaults
        _templates = await _localService.load();
      } else {
        // Save the latest sheet data to local storage
        await _localService.save(_templates);
      }
      _selected = defaultTemplate;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to sync templates with sheet: $e');
    }
  }

  void select(MessageTemplate t) {
    _selected = t;
    notifyListeners();
  }

  Future<void> add(MessageTemplate t) async {
    _templates.add(t);
    // Save locally first (instant)
    await _localService.save(_templates);
    notifyListeners();

    // Save to sheet in the background
    try {
      await _sheetService.addTemplate(t.id, t.name, t.body);
    } catch (e) {
      debugPrint('Failed to save template to sheet: $e');
    }
  }

  Future<void> update(MessageTemplate t) async {
    final i = _templates.indexWhere((x) => x.id == t.id);
    if (i == -1) return;
    _templates[i] = t;

    if (t.isDefault) {
      for (var j = 0; j < _templates.length; j++) {
        if (_templates[j].id != t.id) {
          _templates[j] = _templates[j].copyWith(isDefault: false);
        }
      }
    }

    await _localService.save(_templates);
    if (_selected?.id == t.id) _selected = t;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _templates.removeWhere((t) => t.id == id);
    if (_selected?.id == id) _selected = defaultTemplate;
    await _localService.save(_templates);
    notifyListeners();
  }

  Future<void> setDefault(String id) async {
    for (var i = 0; i < _templates.length; i++) {
      _templates[i] = _templates[i].copyWith(isDefault: _templates[i].id == id);
    }
    await _localService.save(_templates);
    _selected = _templates.firstWhere((t) => t.id == id);
    notifyListeners();
  }
}

// import 'package:flutter/foundation.dart';
// import '../models/message_template.dart';
// import '../services/template_service.dart';
//
// class TemplateProvider extends ChangeNotifier {
//   final TemplateService _service = TemplateService();
//   List<MessageTemplate> _templates = [];
//   MessageTemplate? _selected;
//   bool _loaded = false;
//
//   List<MessageTemplate> get templates => List.unmodifiable(_templates);
//   MessageTemplate? get selected => _selected;
//   bool get loaded => _loaded;
//
//   MessageTemplate? get defaultTemplate =>
//       _templates.isEmpty ? null : _templates.firstWhere(
//             (t) => t.isDefault, orElse: () => _templates.first,
//       );
//
//   Future<void> load() async {
//     _templates = await _service.load();
//     _selected = defaultTemplate;
//     _loaded = true;
//     notifyListeners();
//   }
//
//   void select(MessageTemplate t) {
//     _selected = t;
//     notifyListeners();
//   }
//
//   Future<void> add(MessageTemplate t) async {
//     _templates.add(t);
//     await _service.save(_templates);
//     notifyListeners();
//   }
//
//   Future<void> update(MessageTemplate t) async {
//     final i = _templates.indexWhere((x) => x.id == t.id);
//     if (i == -1) return;
//     _templates[i] = t;
//     if (t.isDefault) {
//       for (var j = 0; j < _templates.length; j++) {
//         if (_templates[j].id != t.id) {
//           _templates[j] = _templates[j].copyWith(isDefault: false);
//         }
//       }
//     }
//     await _service.save(_templates);
//     if (_selected?.id == t.id) _selected = t;
//     notifyListeners();
//   }
//
//   Future<void> delete(String id) async {
//     _templates.removeWhere((t) => t.id == id);
//     if (_selected?.id == id) _selected = defaultTemplate;
//     await _service.save(_templates);
//     notifyListeners();
//   }
//
//   Future<void> setDefault(String id) async {
//     for (var i = 0; i < _templates.length; i++) {
//       _templates[i] = _templates[i].copyWith(isDefault: _templates[i].id == id);
//     }
//     await _service.save(_templates);
//     _selected = _templates.firstWhere((t) => t.id == id);
//     notifyListeners();
//   }
// }