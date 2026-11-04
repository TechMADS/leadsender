import 'package:flutter/foundation.dart';
import '../services/lead_sheet_service.dart';

class DropdownProvider extends ChangeNotifier {
  final LeadSheetService _service = LeadSheetService();
  List<String> _options = [];
  bool _loading = false;

  List<String> get options => _options;
  bool get loading => _loading;

  Future<void> loadOptions() async {
    _loading = true;
    notifyListeners();
    try {
      _options = await _service.fetchDropdownOptions();
    } catch (e) {
      debugPrint('Failed to load options: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addOption(String option) async {
    if (option.trim().isEmpty) return;
    try {
      await _service.addDropdownOption(option.trim());
      await loadOptions();
    } catch (e) {
      debugPrint('Failed to add option: $e');
    }
  }
}