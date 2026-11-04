import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business_profile.dart';

class SettingsService {
  static const _key = 'business_profile';

  Future<BusinessProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const BusinessProfile();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BusinessProfile(
      shopName: map['shopName'] ?? '',
      introduction: map['introduction'] ?? '',
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      catalogueUrl: map['catalogueUrl'] ?? '',
      websiteUrl: map['websiteUrl'] ?? '',
      businessHours: map['businessHours'] ?? '',
      template: map['template'] ?? BusinessProfile.defaultTemplate,
      defaultCountryCode: map['defaultCountryCode'] ?? '+91',
    );
  }

  Future<void> save(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'shopName': profile.shopName,
        'introduction': profile.introduction,
        'address': profile.address,
        'contactNumber': profile.contactNumber,
        'catalogueUrl': profile.catalogueUrl,
        'websiteUrl': profile.websiteUrl,
        'businessHours': profile.businessHours,
        'template': profile.template,
        'defaultCountryCode': profile.defaultCountryCode,
      }),
    );
  }
}