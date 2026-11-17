import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discover_filter_preset.dart';
import '../models/student.dart';
import '../models/team.dart';
import '../models/team_request.dart';

class StorageService {
  static const _kProfile = 'profile';
  static const _kRequests = 'requests';
  static const _kTeam = 'team';
  static const _kDiscoverFilterPresets = 'discover_filter_presets';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  // ---- Profile ----
  Future<void> saveProfile(Student s) async =>
      (await _p).setString(_kProfile, jsonEncode(s.toJson()));

  Future<Student?> loadProfile() async {
    try {
      final raw = (await _p).getString(_kProfile);
      if (raw == null) return null;
      return Student.fromJson(jsonDecode(raw));
    } catch (_) {
      return null; // corrupted data → crash nahi
    }
  }

  // ---- Requests ----
  Future<void> saveRequests(List<TeamRequest> list) async =>
      (await _p).setString(
          _kRequests, jsonEncode(list.map((e) => e.toJson()).toList()));

  /// null = pehli baar (sample data seed hoga)
  Future<List<TeamRequest>?> loadRequests() async {
    try {
      final raw = (await _p).getString(_kRequests);
      if (raw == null) return null;
      return (jsonDecode(raw) as List)
          .map((e) => TeamRequest.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ---- Team ----
  Future<void> saveTeam(Team? t) async {
    final p = await _p;
    if (t == null) {
      await p.remove(_kTeam);
    } else {
      final saved = await p.setString(_kTeam, jsonEncode(t.toJson()));
      if (!saved) throw StateError('Could not save team.');
    }
  }

  Future<Team?> loadTeam() async {
    try {
      final raw = (await _p).getString(_kTeam);
      if (raw == null) return null;
      return Team.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<List<DiscoverFilterPreset>> loadDiscoverFilterPresets() async {
    final raw = (await _p).getString(_kDiscoverFilterPresets);
    if (raw == null) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Invalid saved filters data.');
    }
    return [for (final item in decoded) DiscoverFilterPreset.fromJson(item)];
  }

  Future<void> saveDiscoverFilterPresets(
    List<DiscoverFilterPreset> presets,
  ) async {
    final saved = await (await _p).setString(
      _kDiscoverFilterPresets,
      jsonEncode(presets.map((preset) => preset.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save discover filters.');
  }
}
