class CourseSummary {
  final String id;
  final String name;
  final dynamic  percentage;
  final int bunksAvailable;
  final int noClasses;
  final int bunked;
  final double currentPercentage;
  final List<int> day;

  CourseSummary({
    required this.id,
    required this.name,
    required this.percentage,
    required this.bunksAvailable,
    required this.noClasses,
    required this.bunked,
    required this.currentPercentage,
    required this.day,
  });


  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    return CourseSummary(
      id: json['id'].toString(),
      name: json['name'],
      percentage: json['percentage'],
      bunksAvailable: json['bunks_available'],
      noClasses: json['no_classes'] ?? 0,
      bunked: json['bunked'] ?? 0,
      currentPercentage: (json['current_percentage'] as num?)?.toDouble() ?? 0.0,
      day: (json['day'] as List<dynamic>?)?.cast<int>() ?? [1],
    );
  }
}
