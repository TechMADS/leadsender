import '../models/business_profile.dart';
import '../models/lead.dart';

class MessageTemplateService {

  static String renderBody({
    required String body,
    required BusinessProfile profile,
    required Lead lead,
  }) {
    final websiteLine = profile.websiteUrl.trim().isEmpty
        ? ''
        : '🌐 Website: ${profile.websiteUrl}';

    final replacements = <String, String>{
      '{shop_name}': profile.shopName,
      '{introduction}': profile.introduction,
      '{shop_address}': profile.address,
      '{contact_number}': profile.contactNumber,
      '{catalogue_url}': profile.catalogueUrl,
      '{website_line}': websiteLine,
      '{lead_name}': lead.name ?? '',
      '{phone_number}': lead.normalizedNumber,
    };

    var out = body;
    replacements.forEach((k, v) => out = out.replaceAll(k, v));
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return out;
  }

  /// A reusable sample lead for previews.
  static Lead sampleLead() => Lead(
    normalizedNumber: '+919876543210',
    originalNumber: '9876543210',
    importedAt: DateTime.now(),
    name: 'Raj',
  );

  /// Existing method — keep as-is (or refactor to use renderBody).
  static String render({
    required BusinessProfile profile,
    required Lead lead,
  }) => renderBody(body: profile.template, profile: profile, lead: lead);

  static String previewWithSample(BusinessProfile profile) =>
      render(profile: profile, lead: sampleLead());

  // static String render({
  //   required BusinessProfile profile,
  //   required Lead lead,
  // }) {
  //   final websiteLine = profile.websiteUrl.trim().isEmpty
  //       ? ''
  //       : '🌐 Website: ${profile.websiteUrl}';
  //
  //   final replacements = <String, String>{
  //     '{shop_name}': profile.shopName,
  //     '{introduction}': profile.introduction,
  //     '{shop_address}': profile.address,
  //     '{contact_number}': profile.contactNumber,
  //     '{catalogue_url}': profile.catalogueUrl,
  //     '{website_line}': websiteLine,
  //     '{lead_name}': lead.name ?? '',
  //     '{phone_number}': lead.normalizedNumber,
  //   };
  //
  //   var out = profile.template;
  //   replacements.forEach((k, v) => out = out.replaceAll(k, v));
  //
  //   // Collapse blank lines created by empty optional placeholders.
  //   out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  //   return out;
  // }
  //
  // static String previewWithSample(BusinessProfile profile) {
  //   final sampleLead = Lead(
  //     normalizedNumber: '+919876543210',
  //     originalNumber: '9876543210',
  //     importedAt: DateTime.now(),
  //     name: 'Raj',
  //   );
  //   return render(profile: profile, lead: sampleLead);
  // }
}