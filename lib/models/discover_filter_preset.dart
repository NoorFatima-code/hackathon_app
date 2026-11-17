enum DiscoverSortOrder {
  name('Name A-Z'),
  department('Department'),
  semester('Semester');

  const DiscoverSortOrder(this.label);

  final String label;
}

class DiscoverFilterPreset {
  final String name;
  final String query;
  final String? department;
  final int? semester;
  final String? skill;
  final String? projectType;
  final DiscoverSortOrder sortOrder;

  const DiscoverFilterPreset({
    required this.name,
    this.query = '',
    this.department,
    this.semester,
    this.skill,
    this.projectType,
    this.sortOrder = DiscoverSortOrder.name,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'query': query,
    'department': department,
    'semester': semester,
    'skill': skill,
    'projectType': projectType,
    'sortOrder': sortOrder.name,
  };

  factory DiscoverFilterPreset.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid saved filter.');
    }

    final name = json['name'];
    final query = json['query'];
    final department = json['department'];
    final semester = json['semester'];
    final skill = json['skill'];
    final projectType = json['projectType'];
    final sortValue = json['sortOrder'];

    if (name is! String ||
        (query != null && query is! String) ||
        (department != null && department is! String) ||
        (semester != null && semester is! int) ||
        (skill != null && skill is! String) ||
        (projectType != null && projectType is! String) ||
        (sortValue != null && sortValue is! String)) {
      throw const FormatException('Invalid saved filter.');
    }

    final matchingSortOrders = DiscoverSortOrder.values
        .where((option) => option.name == sortValue)
        .toList();
    if (matchingSortOrders.isEmpty && sortValue != null) {
      throw const FormatException('Invalid saved filter sort order.');
    }

    return DiscoverFilterPreset(
      name: name,
      query: query as String? ?? '',
      department: department as String?,
      semester: semester as int?,
      skill: skill as String?,
      projectType: projectType as String?,
      sortOrder: matchingSortOrders.isEmpty
          ? DiscoverSortOrder.name
          : matchingSortOrders.first,
    );
  }
}
