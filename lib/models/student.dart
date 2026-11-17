class Student {
  final String id;
  final String name;
  final String department;
  final int semester;
  final List<String> skills;
  final List<String> interests;
  final String projectType;
  final String availability;
  final String bio;
  final String? photoData;

  const Student({
    required this.id,
    required this.name,
    required this.department,
    required this.semester,
    required this.skills,
    required this.interests,
    required this.projectType,
    required this.availability,
    this.bio = '',
    this.photoData,
  });

  Student copyWith({
    String? name,
    String? department,
    int? semester,
    List<String>? skills,
    List<String>? interests,
    String? projectType,
    String? availability,
    String? bio,
    String? photoData,
  }) =>
      Student(
        id: id,
        name: name ?? this.name,
        department: department ?? this.department,
        semester: semester ?? this.semester,
        skills: skills ?? this.skills,
        interests: interests ?? this.interests,
        projectType: projectType ?? this.projectType,
        availability: availability ?? this.availability,
        bio: bio ?? this.bio,
        photoData: photoData ?? this.photoData,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'semester': semester,
        'skills': skills,
        'interests': interests,
        'projectType': projectType,
        'availability': availability,
        'bio': bio,
        'photoData': photoData,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'] as String,
        name: j['name'] as String,
        department: j['department'] as String,
        semester: j['semester'] as int,
        skills: List<String>.from(j['skills'] ?? []),
        interests: List<String>.from(j['interests'] ?? []),
        projectType: j['projectType'] as String,
        availability: j['availability'] as String,
        bio: (j['bio'] ?? '') as String,
        photoData: j['photoData'] as String?,
      );
}
