import 'package:flutter/foundation.dart';
import '../models/business_profile.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();
  BusinessProfile _profile = const BusinessProfile();
  bool _loaded = false;

  BusinessProfile get profile => _profile;
  bool get loaded => _loaded;

  Future<void> load() async {
    _profile = await _service.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(BusinessProfile profile) async {
    _profile = profile;
    await _service.save(profile);
    notifyListeners();
  }
}