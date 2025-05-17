class FormConfig {
  final String documentTypeId;
  final String name;
  final List<FormFieldConfig> fields;

  FormConfig({
    required this.documentTypeId,
    required this.name,
    required this.fields,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentTypeId': documentTypeId,
      'name': name,
      'fields': fields.map((field) => field.toMap()).toList(),
    };
  }

  factory FormConfig.fromMap(Map<String, dynamic> map) {
    return FormConfig(
      documentTypeId: map['documentTypeId'] ?? '',
      name: map['name'] ?? '',
      fields: map['fields'] != null
          ? List<FormFieldConfig>.from(map['fields'].map((field) => FormFieldConfig.fromMap(field)))
          : [],
    );
  }
}

class FormFieldConfig {
  final String id;
  final String type; // "paragraph", "checkbox", "text", etc.
  final String label;
  final String? description;
  final List<String>? options; // For checkbox or radio fields

  FormFieldConfig({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'description': description,
      'options': options,
    };
  }

  factory FormFieldConfig.fromMap(Map<String, dynamic> map) {
    return FormFieldConfig(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      label: map['label'] ?? '',
      description: map['description'],
      options: map['options'] != null ? List<String>.from(map['options']) : null,
    );
  }
}