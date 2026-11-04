class BusinessProfile {
  final String shopName;
  final String introduction;
  final String address;
  final String contactNumber;
  final String catalogueUrl;
  final String websiteUrl;
  final String businessHours;
  final String template;
  final String defaultCountryCode;

  const BusinessProfile({
    this.shopName = '',
    this.introduction = '',
    this.address = '',
    this.contactNumber = '',
    this.catalogueUrl = '',
    this.websiteUrl = '',
    this.businessHours = '',
    this.template = defaultTemplate,
    this.defaultCountryCode = '+91',
  });

  static const String defaultTemplate = '''Hi! 👋

We would like to introduce {shop_name}.

{introduction}

📋 Explore our catalogue: {catalogue_url}

📍 Address: {shop_address}

📞 Contact: {contact_number}

{website_line}

If you are interested, please feel free to contact us.

Thank you!''';

  BusinessProfile copyWith({
    String? shopName,
    String? introduction,
    String? address,
    String? contactNumber,
    String? catalogueUrl,
    String? websiteUrl,
    String? businessHours,
    String? template,
    String? defaultCountryCode,
  }) => BusinessProfile(
    shopName: shopName ?? this.shopName,
    introduction: introduction ?? this.introduction,
    address: address ?? this.address,
    contactNumber: contactNumber ?? this.contactNumber,
    catalogueUrl: catalogueUrl ?? this.catalogueUrl,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    businessHours: businessHours ?? this.businessHours,
    template: template ?? this.template,
    defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
  );
}