import 'package:flutter_test/flutter_test.dart';
import 'package:jobtime_proof/models/job_session.dart';
import 'package:jobtime_proof/providers/session_provider.dart';

JobSession _sessionAt(DateTime start) => JobSession(
  id: start.toIso8601String(),
  platform: 'Indeed',
  actionType: 'recherche d\'offres',
  startTime: start,
  endTime: start.add(const Duration(minutes: 30)),
  durationSeconds: 1800,
  notes: '',
  proofs: const [],
  didApply: false,
  createdAt: start,
  updatedAt: start,
);

void main() {
  // A date range picker returns both bounds at midnight.
  final from = DateTime(2026, 3, 2);
  final to = DateTime(2026, 3, 4);

  bool inRange(DateTime start) =>
      SessionProvider.isInDayRange(_sessionAt(start), from, to);

  test('le dernier jour de la période est inclus', () {
    expect(inRange(DateTime(2026, 3, 4, 18, 45)), isTrue);
  });

  test('une période d\'un seul jour contient les sessions de ce jour', () {
    final day = DateTime(2026, 3, 4);
    expect(
      SessionProvider.isInDayRange(
        _sessionAt(DateTime(2026, 3, 4, 10)),
        day,
        day,
      ),
      isTrue,
    );
  });

  test('les bornes de la période sont respectées', () {
    expect(inRange(DateTime(2026, 3, 2)), isTrue);
    expect(inRange(DateTime(2026, 3, 1, 23, 59)), isFalse);
    expect(inRange(DateTime(2026, 3, 5)), isFalse);
  });
}
