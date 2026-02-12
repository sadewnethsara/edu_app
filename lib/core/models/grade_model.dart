class GradeModel {
  final String id;
  final int order;
  final String name;
  final String description;
  final bool isActive;

  GradeModel({
    required this.id,
    required this.order,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as String,
      order: json['order'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'name': name,
      'description': description,
      'isActive': isActive,
    };
  }
}
