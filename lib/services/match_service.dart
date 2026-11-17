import '../models/student.dart';
import '../models/team.dart';

class MatchResult {
  final Student student;
  final int score; // 0-100
  final List<String> reasons;
  final Set<String> matchedSkills;

  const MatchResult(this.student, this.score, this.reasons, this.matchedSkills);
}

class MatchService {
  /// Score breakdown: interests 40 + skills 25 + project type 20 + availability 15
  static MatchResult score(Student me, Student other, Team? team) {
    final reasons = <String>[];
    var total = 0.0;

    // 1) Shared interests (40)
    final sharedInterests =
        other.interests.where(me.interests.contains).toList();
    if (sharedInterests.isNotEmpty) {
      final denom = me.interests.length < 2 ? 1 : 2;
      total += 40 * (sharedInterests.length / denom).clamp(0.0, 1.0);
      final n = sharedInterests.length;
      reasons.add(
          '$n shared interest${n > 1 ? 's' : ''}: ${sharedInterests.join(', ')}');
    }

    // 2) Skills needed (25): team ke open roles, warna jo skills mere paas nahi
    final hasTeamRoles = team != null && team.rolesNeeded.isNotEmpty;
    final needed = hasTeamRoles
        ? team.rolesNeeded
        : [
            for (final s in other.skills)
              if (!me.skills.contains(s)) s
          ];
    final matched = other.skills.where(needed.contains).toSet();
    if (matched.isNotEmpty) {
      total += 25 * (matched.length / 2).clamp(0.0, 1.0);
      reasons.add(
          'Has ${matched.join(', ')}, which ${hasTeamRoles ? 'your team needs' : 'you could use'}');
    }

    // 3) Same project type (20)
    if (other.projectType == me.projectType) {
      total += 20;
      reasons.add('Same project type: ${me.projectType}');
    }

    // 4) Availability (15)
    if (other.availability == me.availability) {
      total += 15;
      reasons.add('Both available ${me.availability}');
    } else if (other.availability == 'Flexible' || me.availability == 'Flexible') {
      total += 10;
      reasons.add('Flexible schedule');
    }

    return MatchResult(other, total.round(), reasons, matched);
  }

  static List<MatchResult> bestMatches(
      Student me, List<Student> all, Team? team) {
    final results = [
      for (final s in all)
        if (s.id != me.id && !(team?.memberIds.contains(s.id) ?? false))
          score(me, s, team)
    ].where((r) => r.score > 0).toList();

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}