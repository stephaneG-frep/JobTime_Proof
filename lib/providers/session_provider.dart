import 'dart:async';

import 'package:flutter/material.dart';

import '../models/job_proof.dart';
import '../models/job_session.dart';
import '../services/hive_service.dart';

class SessionProvider extends ChangeNotifier {
  static const _draftStateKey = 'active_session_draft';
  final List<String> actionTypes = const [
    'recherche d\'offres',
    'candidature envoyée',
    'mise à jour CV',
    'message recruteur',
    'entretien',
    'formation',
  ];

  List<JobSession> _sessions = [];
  List<JobSession> get sessions => List.unmodifiable(_sessions);

  String _selectedPlatform = 'France Travail';
  String _selectedActionType = 'recherche d\'offres';
  String get selectedPlatform => _selectedPlatform;
  String get selectedActionType => _selectedActionType;

  DateTime? _runningStart;
  int _elapsedBeforeCurrentRun = 0;
  DateTime? _lastRunResumedAt;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  String _draftNotes = '';
  bool _draftDidApply = false;
  final List<String> _draftUrls = [];
  final List<bool> _draftUrlDidApply = [];
  String? _pendingSharedUrl;

  DateTime? get runningStart => _runningStart;
  int get elapsedSeconds {
    if (!_isRunning || _isPaused || _lastRunResumedAt == null) {
      return _elapsedBeforeCurrentRun;
    }
    final delta = DateTime.now().difference(_lastRunResumedAt!).inSeconds;
    return _elapsedBeforeCurrentRun + (delta < 0 ? 0 : delta);
  }

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  String get draftNotes => _draftNotes;
  bool get draftDidApply => _draftDidApply;
  List<String> get draftUrls => List.unmodifiable(_draftUrls);
  List<bool> get draftUrlDidApply => List.unmodifiable(_draftUrlDidApply);
  String? get pendingSharedUrl => _pendingSharedUrl;

  Future<void> load() async {
    _sessions = HiveService.sessionsBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    _restoreDraftState();
    notifyListeners();
  }

  void setPlatform(String value) {
    _selectedPlatform = value;
    _persistDraftState();
    notifyListeners();
  }

  void setActionType(String value) {
    _selectedActionType = value;
    if (value.toLowerCase().contains('candidature')) {
      _draftDidApply = true;
    }
    _persistDraftState();
    notifyListeners();
  }

  void setDraftNotes(String value) {
    _draftNotes = value;
    _persistDraftState();
    notifyListeners();
  }

  void setDraftDidApply(bool value) {
    _draftDidApply = value;
    _persistDraftState();
    notifyListeners();
  }

  void addDraftUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _draftUrls.contains(trimmed)) return;
    _draftUrls.add(trimmed);
    _draftUrlDidApply.add(false);
    _persistDraftState();
    notifyListeners();
  }

  void removeDraftUrlAt(int index) {
    if (index < 0 || index >= _draftUrls.length) return;
    _draftUrls.removeAt(index);
    if (index < _draftUrlDidApply.length) {
      _draftUrlDidApply.removeAt(index);
    }
    _draftDidApply = _draftDidApply || _draftUrlDidApply.any((value) => value);
    _persistDraftState();
    notifyListeners();
  }

  void setDraftUrlDidApplyAt(int index, bool value) {
    if (index < 0 || index >= _draftUrls.length) return;
    _syncDraftUrlFlags();
    _draftUrlDidApply[index] = value;
    if (value) {
      _draftDidApply = true;
    }
    _persistDraftState();
    notifyListeners();
  }

  void clearDraftUrls() {
    _draftUrls.clear();
    _draftUrlDidApply.clear();
    _persistDraftState();
    notifyListeners();
  }

  void setPendingSharedUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _pendingSharedUrl = trimmed;
    _persistDraftState();
    notifyListeners();
  }

  String? consumePendingSharedUrl() {
    final value = _pendingSharedUrl;
    _pendingSharedUrl = null;
    _persistDraftState();
    notifyListeners();
    return value;
  }

  void clearPendingSharedUrl() {
    _pendingSharedUrl = null;
    _persistDraftState();
    notifyListeners();
  }

  void startSession() {
    if (_isRunning && !_isPaused) return;

    if (_runningStart == null) {
      _runningStart = DateTime.now();
      _elapsedBeforeCurrentRun = 0;
    }

    _isRunning = true;
    _isPaused = false;
    _lastRunResumedAt = DateTime.now();
    _persistDraftState();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Tick only drives UI refresh; elapsed time is based on real timestamps.
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseSession() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _elapsedBeforeCurrentRun = elapsedSeconds;
    _lastRunResumedAt = null;
    _isPaused = true;
    _persistDraftState();
    notifyListeners();
  }

  Future<JobSession?> endSession() async {
    if (_runningStart == null || !_isRunning) return null;
    _timer?.cancel();

    final now = DateTime.now();
    final sessionId = now.microsecondsSinceEpoch.toString();
    _syncDraftUrlFlags();
    final finalizedProofs = _draftUrls
        .asMap()
        .entries
        .map(
          (entry) => JobProof(
            id: '${now.microsecondsSinceEpoch}_${entry.value.hashCode}',
            sessionId: sessionId,
            title: 'Lien session',
            type: JobProofType.url,
            url: entry.value,
            didApply: _draftUrlAppliedAt(entry.key),
            createdAt: now,
          ),
        )
        .toList();
    final didApply =
        _draftDidApply ||
        finalizedProofs.any((proof) => proof.didApply) ||
        _selectedActionType.toLowerCase().contains('candidature');
    final session = JobSession(
      id: sessionId,
      platform: _selectedPlatform,
      actionType: _selectedActionType,
      startTime: _runningStart!,
      endTime: now,
      durationSeconds: elapsedSeconds,
      notes: _draftNotes.trim(),
      proofs: finalizedProofs,
      didApply: didApply,
      createdAt: now,
      updatedAt: now,
    );

    await HiveService.sessionsBox.put(session.id, session);
    _sessions.insert(0, session);

    _runningStart = null;
    _elapsedBeforeCurrentRun = 0;
    _lastRunResumedAt = null;
    _isRunning = false;
    _isPaused = false;
    _draftNotes = '';
    _draftDidApply = false;
    _draftUrls.clear();
    _draftUrlDidApply.clear();
    _pendingSharedUrl = null;
    await HiveService.runtimeBox.delete(_draftStateKey);

    notifyListeners();
    return session;
  }

  Future<JobSession> saveEstimatedSession({required int minutes}) async {
    final now = DateTime.now();
    final safeMinutes = minutes < 1 ? 10 : minutes;
    final start = now.subtract(Duration(minutes: safeMinutes));
    final sessionId = now.microsecondsSinceEpoch.toString();
    _syncDraftUrlFlags();
    final finalizedProofs = _draftUrls
        .asMap()
        .entries
        .map(
          (entry) => JobProof(
            id: '${now.microsecondsSinceEpoch}_${entry.value.hashCode}',
            sessionId: sessionId,
            title: 'Lien session',
            type: JobProofType.url,
            url: entry.value,
            didApply: _draftUrlAppliedAt(entry.key),
            createdAt: now,
          ),
        )
        .toList();
    final didApply =
        _draftDidApply ||
        finalizedProofs.any((proof) => proof.didApply) ||
        _selectedActionType.toLowerCase().contains('candidature');
    final session = JobSession(
      id: sessionId,
      platform: _selectedPlatform,
      actionType: _selectedActionType,
      startTime: start,
      endTime: now,
      durationSeconds: safeMinutes * 60,
      notes: _draftNotes.trim(),
      proofs: finalizedProofs,
      didApply: didApply,
      createdAt: now,
      updatedAt: now,
    );

    await HiveService.sessionsBox.put(session.id, session);
    _sessions.insert(0, session);

    _draftNotes = '';
    _draftDidApply = false;
    _draftUrls.clear();
    _draftUrlDidApply.clear();
    _pendingSharedUrl = null;
    await HiveService.runtimeBox.delete(_draftStateKey);

    notifyListeners();
    return session;
  }

  Future<void> addProof(String sessionId, JobProof proof) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final updatedProofs = [..._sessions[index].proofs, proof];
    final updated = _sessions[index].copyWith(proofs: updatedProofs);

    _sessions[index] = updated;
    await HiveService.sessionsBox.put(updated.id, updated);
    notifyListeners();
  }

  Future<void> setProofDidApply({
    required String sessionId,
    required String proofId,
    required bool didApply,
  }) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;

    final session = _sessions[index];
    final updatedProofs = session.proofs
        .map(
          (proof) =>
              proof.id == proofId ? proof.copyWith(didApply: didApply) : proof,
        )
        .toList();
    final updated = session.copyWith(
      proofs: updatedProofs,
      didApply:
          session.didApply || updatedProofs.any((proof) => proof.didApply),
    );

    _sessions[index] = updated;
    await HiveService.sessionsBox.put(updated.id, updated);
    notifyListeners();
  }

  Future<bool> addUrlProofToLatestSession({
    required String url,
    String title = 'Annonce partagée',
    String? description,
  }) async {
    if (_sessions.isEmpty) return false;
    final latest = _sessions.first;
    final proof = JobProof(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sessionId: latest.id,
      title: title,
      type: JobProofType.url,
      url: url.trim(),
      description: description,
      createdAt: DateTime.now(),
    );
    await addProof(latest.id, proof);
    return true;
  }

  Future<void> updateSession(JobSession updated) async {
    final idx = _sessions.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    _sessions[idx] = updated;
    await HiveService.sessionsBox.put(updated.id, updated);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await HiveService.sessionsBox.delete(id);
    notifyListeners();
  }

  Future<void> replaceAllSessions(List<JobSession> imported) async {
    final box = HiveService.sessionsBox;
    await box.clear();
    for (final s in imported) {
      await box.put(s.id, s);
    }
    _sessions = imported..sort((a, b) => b.startTime.compareTo(a.startTime));
    notifyListeners();
  }

  Future<void> clearAll() async {
    await HiveService.sessionsBox.clear();
    _sessions = [];
    notifyListeners();
  }

  int totalProofsCount() =>
      _sessions.fold<int>(0, (sum, s) => sum + s.proofs.length);

  int sessionsWithoutProofCount() =>
      _sessions.where((session) => !session.hasProofs).length;

  Future<int> normalizePlatformNames(List<String> validPlatforms) async {
    var updatedCount = 0;
    final normalizedByKey = {
      for (final platform in validPlatforms)
        platform.trim().toLowerCase(): platform,
    };

    for (var i = 0; i < _sessions.length; i++) {
      final current = _sessions[i].platform.trim();
      final normalized = normalizedByKey[current.toLowerCase()];
      if (normalized == null || normalized == _sessions[i].platform) continue;
      final updated = _sessions[i].copyWith(platform: normalized);
      _sessions[i] = updated;
      await HiveService.sessionsBox.put(updated.id, updated);
      updatedCount++;
    }

    final selected = normalizedByKey[_selectedPlatform.trim().toLowerCase()];
    if (selected != null && selected != _selectedPlatform) {
      _selectedPlatform = selected;
      _persistDraftState();
      updatedCount++;
    }

    if (updatedCount > 0) notifyListeners();
    return updatedCount;
  }

  int totalSecondsToday() {
    final now = DateTime.now();
    return _sessions
        .where(
          (s) =>
              s.startTime.year == now.year &&
              s.startTime.month == now.month &&
              s.startTime.day == now.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  int totalSecondsWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _sessions
        .where((s) => !s.startTime.isBefore(startOfWeek))
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
  }

  List<JobSession> sessionsForPeriod(DateTime from, DateTime to) {
    return _sessions.where((s) {
      final startsAfterOrAt = !s.startTime.isBefore(from);
      final endsBeforeOrAt = !s.endTime.isAfter(to);
      return startsAfterOrAt && endsBeforeOrAt;
    }).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _persistDraftState() {
    final box = HiveService.runtimeBox;
    final map = <String, dynamic>{
      'selectedPlatform': _selectedPlatform,
      'selectedActionType': _selectedActionType,
      'runningStart': _runningStart?.toIso8601String(),
      'elapsedBeforeCurrentRun': _elapsedBeforeCurrentRun,
      'lastRunResumedAt': _lastRunResumedAt?.toIso8601String(),
      'isRunning': _isRunning,
      'isPaused': _isPaused,
      'draftNotes': _draftNotes,
      'draftDidApply': _draftDidApply,
      'draftUrls': _draftUrls,
      'draftUrlDidApply': _draftUrlDidApply,
      'pendingSharedUrl': _pendingSharedUrl,
    };
    box.put(_draftStateKey, map);
  }

  void _restoreDraftState() {
    final raw = HiveService.runtimeBox.get(_draftStateKey);
    if (raw is! Map) return;

    _selectedPlatform =
        (raw['selectedPlatform'] as String?) ?? _selectedPlatform;
    _selectedActionType =
        (raw['selectedActionType'] as String?) ?? _selectedActionType;
    _runningStart = DateTime.tryParse((raw['runningStart'] as String?) ?? '');
    _elapsedBeforeCurrentRun = (raw['elapsedBeforeCurrentRun'] as int?) ?? 0;
    _lastRunResumedAt = DateTime.tryParse(
      (raw['lastRunResumedAt'] as String?) ?? '',
    );
    _isRunning = (raw['isRunning'] as bool?) ?? false;
    _isPaused = (raw['isPaused'] as bool?) ?? false;
    _draftNotes = (raw['draftNotes'] as String?) ?? '';
    _draftDidApply =
        (raw['draftDidApply'] as bool?) ??
        _selectedActionType.toLowerCase().contains('candidature');
    _draftUrls
      ..clear()
      ..addAll(
        ((raw['draftUrls'] as List?) ?? const <dynamic>[]).cast<String>(),
      );
    _draftUrlDidApply
      ..clear()
      ..addAll(
        ((raw['draftUrlDidApply'] as List?) ?? const <dynamic>[]).map(
          (value) => value == true,
        ),
      );
    _syncDraftUrlFlags();
    _pendingSharedUrl = (raw['pendingSharedUrl'] as String?);

    if (_isRunning && !_isPaused) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
      });
    }
  }

  bool _draftUrlAppliedAt(int index) {
    return index >= 0 &&
        index < _draftUrlDidApply.length &&
        _draftUrlDidApply[index];
  }

  void _syncDraftUrlFlags() {
    while (_draftUrlDidApply.length < _draftUrls.length) {
      _draftUrlDidApply.add(false);
    }
    while (_draftUrlDidApply.length > _draftUrls.length) {
      _draftUrlDidApply.removeLast();
    }
  }
}
