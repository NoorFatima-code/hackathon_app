import 'team_chat_message.dart';

class Team {
  final String title;
  final String projectType;
  final List<String> rolesNeeded;
  final List<String> skillsNeeded;
  final List<String> memberIds; // pehla member = me
  final Map<String, List<String>> memberRoles;
  final List<TeamChatMessage> messages;

  const Team({
    required this.title,
    required this.projectType,
    required this.rolesNeeded,
    this.skillsNeeded = const [],
    required this.memberIds,
    this.memberRoles = const {},
    this.messages = const [],
  });

  Team copyWith({
    List<String>? rolesNeeded,
    List<String>? skillsNeeded,
    List<String>? memberIds,
    Map<String, List<String>>? memberRoles,
    List<TeamChatMessage>? messages,
  }) => Team(
        title: title,
        projectType: projectType,
        rolesNeeded: rolesNeeded ?? this.rolesNeeded,
        skillsNeeded: skillsNeeded ?? this.skillsNeeded,
        memberIds: memberIds ?? this.memberIds,
        memberRoles: memberRoles ?? this.memberRoles,
        messages: messages ?? this.messages,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'projectType': projectType,
        'rolesNeeded': rolesNeeded,
        'skillsNeeded': skillsNeeded,
        'memberIds': memberIds,
        'memberRoles': memberRoles,
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  factory Team.fromJson(Map<String, dynamic> j) {
    final oldNeeds = List<String>.from(j['rolesNeeded'] ?? []);
    final hasSeparateNeeds = j.containsKey('skillsNeeded');
    return Team(
      title: j['title'] as String,
      projectType: j['projectType'] as String,
      rolesNeeded: hasSeparateNeeds ? oldNeeds : const [],
      skillsNeeded: hasSeparateNeeds
          ? List<String>.from(j['skillsNeeded'] ?? [])
          : oldNeeds,
      memberIds: List<String>.from(j['memberIds'] ?? []),
      memberRoles: _memberRolesFromJson(j['memberRoles']),
      messages: [
        for (final message in (j['messages'] as List? ?? const []))
          TeamChatMessage.fromJson(Map<String, dynamic>.from(message)),
      ],
    );
  }
}

Map<String, List<String>> _memberRolesFromJson(Object? value) {
  if (value == null) return {};
  if (value is! Map) {
    throw const FormatException('Invalid team member roles.');
  }

  final roles = <String, List<String>>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! List) {
      throw const FormatException('Invalid team member roles.');
    }
    roles[entry.key as String] = List<String>.from(entry.value as List);
  }
  return roles;
}
