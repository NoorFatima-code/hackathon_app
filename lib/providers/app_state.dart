import 'package:flutter/foundation.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../models/team.dart';
import '../models/team_request.dart';
import '../services/storage_service.dart';

const meId = 'me';

class AppState extends ChangeNotifier {
  final _storage = StorageService();

  bool loading = true;
  String? error;
  Student? me;
  List<TeamRequest> requests = [];
  Team? team;

  List<Student> get students => sampleStudents;

  Future<void> init() async {
    try {
      me = await _storage.loadProfile();
      final saved = await _storage.loadRequests();
      requests = saved ?? sampleReceivedRequests();
      if (saved == null) await _storage.saveRequests(requests);
      team = await _storage.loadTeam();
    } catch (_) {
      error = 'Could not load data. Please restart the app.';
    }
    loading = false;
    notifyListeners();
  }

  // ---------- Profile ----------
  Future<void> saveProfile(Student s) async {
    me = s;
    notifyListeners();
    await _storage.saveProfile(s);
  }

  Student? studentById(String id) {
    if (id == meId) return me;
    for (final s in sampleStudents) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ---------- Requests ----------
  List<TeamRequest> get sent =>
      requests.where((r) => r.direction == RequestDirection.sent).toList();

  List<TeamRequest> get received =>
      requests.where((r) => r.direction == RequestDirection.received).toList();

  int get pendingReceivedCount =>
      received.where((r) => r.status == RequestStatus.pending).length;

  bool hasPendingTo(String studentId) => requests.any((r) =>
      r.direction == RequestDirection.sent &&
      r.student.id == studentId &&
      r.status == RequestStatus.pending);

  /// false = already pending hai (duplicate nahi banega)
  Future<bool> sendRequest(Student to, String message) async {
    if (hasPendingTo(to.id)) return false;
    requests = [
      TeamRequest(
        id: 'q${DateTime.now().millisecondsSinceEpoch}',
        student: to,
        message: message.trim().isEmpty ? 'Hi! Let\'s team up.' : message.trim(),
        direction: RequestDirection.sent,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      ),
      ...requests,
    ];
    notifyListeners();
    await _storage.saveRequests(requests);
    return true;
  }

  Future<void> cancelRequest(String id) =>
      _setStatus(id, RequestStatus.cancelled);

  Future<void> respondToRequest(String id, {required bool accept}) async {
    if (accept) {
      final r = requests.firstWhere((e) => e.id == id);
      final t = team;
      if (t != null && !t.memberIds.contains(r.student.id)) {
        team = t.copyWith(memberIds: [...t.memberIds, r.student.id]);
        await _storage.saveTeam(team);
      }
    }
    await _setStatus(
        id, accept ? RequestStatus.accepted : RequestStatus.rejected);
  }

  Future<void> _setStatus(String id, RequestStatus status) async {
    requests = [
      for (final r in requests) r.id == id ? r.copyWith(status: status) : r
    ];
    notifyListeners();
    await _storage.saveRequests(requests);
  }

  // ---------- Team ----------
  Future<void> createTeam(
      String title, String projectType, List<String> roles) async {
    team = Team(
      title: title.trim(),
      projectType: projectType,
      rolesNeeded: roles,
      memberIds: [meId],
    );
    notifyListeners();
    await _storage.saveTeam(team);
  }

  Future<void> leaveTeam() async {
    team = null;
    notifyListeners();
    await _storage.saveTeam(null);
  }
}