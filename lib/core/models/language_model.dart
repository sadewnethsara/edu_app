class LanguageModel {
  final String code;
  final String label;
  final String nativeName;
  final bool isActive;
  final int order;

  LanguageModel({
    required this.code,
    required this.label,
    required this.nativeName,
    required this.isActive,
    required this.order,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] as String,
      label: json['label'] as String,
      nativeName: json['nativeName'] as String,
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'nativeName': nativeName,
      'isActive': isActive,
      'order': order,
    };
  }
}
