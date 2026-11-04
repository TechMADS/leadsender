import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_profile.dart';
import '../models/message_template.dart';

class TemplateService {
  static const _key = 'message_templates_v1';

  Future<List<MessageTemplate>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      // Seed from the existing business profile template on first run.
      final seed = MessageTemplate(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'Default',
        body: BusinessProfile.defaultTemplate,
        isDefault: true,
      );
      await save([seed]);
      return [seed];
    }
    final list = (jsonDecode(raw) as List)
        .map((e) => MessageTemplate.fromMap(e as Map<String, Object?>))
        .toList();
    if (list.isEmpty) {
      return load();
    }
    return list;
  }

  Future<void> save(List<MessageTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(templates.map((t) => t.toMap()).toList()),
    );
  }
}