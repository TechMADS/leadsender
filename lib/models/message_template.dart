class MessageTemplate {
  final String id;
  String name;
  String body;
  bool isDefault;

  MessageTemplate({
    required this.id,
    required this.name,
    required this.body,
    this.isDefault = false,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'body': body,
    'isDefault': isDefault,
  };

  factory MessageTemplate.fromMap(Map<String, Object?> m) => MessageTemplate(
    id: m['id'] as String,
    name: m['name'] as String,
    body: m['body'] as String,
    isDefault: (m['isDefault'] as bool?) ?? false,
  );

  MessageTemplate copyWith({String? name, String? body, bool? isDefault}) =>
      MessageTemplate(
        id: id,
        name: name ?? this.name,
        body: body ?? this.body,
        isDefault: isDefault ?? this.isDefault,
      );
}