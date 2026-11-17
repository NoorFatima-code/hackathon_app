class Team {
  final String title;
  final String projectType;
  final List<String> rolesNeeded;
  final List<String> memberIds; // pehla member = me

  const Team({
    required this.title,
    required this.projectType,
    required this.rolesNeeded,
    required this.memberIds,
  });

  Team copyWith({List<String>? rolesNeeded, List<String>? memberIds}) => Team(
        title: title,
        projectType: projectType,
        rolesNeeded: rolesNeeded ?? this.rolesNeeded,
        memberIds: memberIds ?? this.memberIds,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'projectType': projectType,
        'rolesNeeded': rolesNeeded,
        'memberIds': memberIds,
      };

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        title: j['title'] as String,
        projectType: j['projectType'] as String,
        rolesNeeded: List<String>.from(j['rolesNeeded'] ?? []),
        memberIds: List<String>.from(j['memberIds'] ?? []),
      );
}