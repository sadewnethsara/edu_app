/// Subject model within a grade
class SubjectModel {
  final String id;
  final String gradeId;
  final int order;
  final String name;
  final String description;
  final String? icon;
  final bool isActive;

  SubjectModel({
    required this.id,
    required this.gradeId,
    required this.order,
    required this.name,
    required this.description,
    this.icon,
    required this.isActive,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      gradeId: json['gradeId'] as String,
      order: json['order'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      // ✅ FIXED: Handle both bool and bool? from Firestore
      isActive: (json['isActive'] == true || json['isActive'] == null)
          ? true
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gradeId': gradeId,
      'order': order,
      'name': name,
      'description': description,
      if (icon != null) 'icon': icon,
      'isActive': isActive,
    };
  }
}
