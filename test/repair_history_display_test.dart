import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/repair_history_display.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';

void main() {
  test('symptom plus short fix is the headline', () {
    expect(
      repairHistoryHeadline(
        _outcome(
          startSymptom: 'No heat',
          immediateCause: 'vent cleared',
        ),
      ),
      'No heat — vent cleared',
    );
    expect(repairHistoryCauseLine(_outcome(
      startSymptom: 'No heat',
      immediateCause: 'vent cleared',
    )), isNull);
  });

  test('verified thermal-fuse path stays short when the cause is long', () {
    const cause =
        'The thermal fuse has opened and interrupted power to the heater circuit.';
    final outcome = _outcome(
      rankingLeaderFailureModeId: 'thermal-fuse-open',
      rankingLeaderLabel: 'Thermal fuse open',
      immediateCause: cause,
      rootCause: 'Restricted exhaust overheated the cabinet.',
    );
    expect(repairHistoryHeadline(outcome), 'Thermal fuse path — verified');
    expect(repairHistoryCauseLine(outcome), contains(cause));
    expect(
      repairHistoryCauseLine(outcome),
      contains('Restricted exhaust overheated the cabinet.'),
    );
  });

  test('member attribution line is by name', () {
    expect(repairHistoryMemberLine('Alex'), 'by Alex');
    expect(repairHistoryMemberLine('  '), isNull);
  });

  test('short fix wins over verified path suffix', () {
    expect(
      repairHistoryHeadline(
        _outcome(
          rankingLeaderFailureModeId: 'thermal-fuse-open',
          rankingLeaderLabel: 'Thermal fuse open',
          immediateCause: 'Fuse replaced',
        ),
      ),
      'Thermal fuse path — Fuse replaced',
    );
  });

  test('washer drain-filter path uses a plain label', () {
    expect(
      repairHistoryHeadline(
        _outcome(
          rankingLeaderFailureModeId: 'clogged-washer-drain-filter',
          rankingLeaderLabel: 'Clogged drain filter or pump trap',
          immediateCause:
              'Lint, coins, or debris in the accessible drain filter can leave '
              'water in the drum for a long time.',
        ),
      ),
      'Drain filter path — verified',
    );
    expect(
      repairHistoryCauseLine(
        _outcome(
          rankingLeaderFailureModeId: 'clogged-washer-drain-filter',
          rankingLeaderLabel: 'Clogged drain filter or pump trap',
          immediateCause:
              'Lint, coins, or debris in the accessible drain filter can leave '
              'water in the drum for a long time.',
        ),
      ),
      contains('Lint, coins, or debris'),
    );
    expect(
      repairHistoryCauseLine(
        _outcome(
          rankingLeaderFailureModeId: 'clogged-washer-drain-filter',
          rankingLeaderLabel: 'Clogged drain filter or pump trap',
          immediateCause: 'Debris in the accessible drain filter',
        ),
      ),
      isNull,
    );
  });

  test('dishwasher tub-filter path uses a plain label', () {
    expect(
      repairHistoryHeadline(
        _outcome(
          rankingLeaderFailureModeId: 'clogged-dishwasher-filter',
          rankingLeaderLabel: 'Clogged tub filter',
          immediateCause:
              'Food debris in the accessible filter at the tub bottom can leave '
              'standing water after a cycle.',
        ),
      ),
      'Tub filter path — verified',
    );
  });

  test('empty cause and missing path still show a close-kind label', () {
    expect(
      repairHistoryHeadline(
        _outcome(
          closeKind: SessionCloseKind.stopped,
          verified: false,
          immediateCause: '',
        ),
      ),
      'Stopped',
    );
  });

  test('optional note, prevention, and DIY spend are extra lines when set', () {
    expect(repairHistoryExtraLines(_outcome()), isEmpty);
    expect(
      repairHistoryExtraLines(
        _outcome(userNote: '  Kept the receipt  ', diyCostUsd: 12),
      ),
      ['Kept the receipt', 'DIY about \$12'],
    );
    expect(
      repairHistoryExtraLines(
        _outcome(
          contributingFactors: const ['Skipped filter cleaning'],
          preventiveActions: const [
            'Check pockets before washing',
            'Clean the drain filter about every 30 days',
          ],
        ),
      ),
      [
        'Also: Skipped filter cleaning',
        'Prevent: Check pockets before washing · '
            'Clean the drain filter about every 30 days',
      ],
    );
  });
}

SessionOutcome _outcome({
  SessionCloseKind closeKind = SessionCloseKind.fixed,
  bool verified = true,
  String immediateCause = '',
  String? rootCause,
  String? startSymptom,
  String? rankingLeaderLabel,
  String? rankingLeaderFailureModeId,
  String? userNote,
  double? diyCostUsd,
  List<String> contributingFactors = const [],
  List<String> preventiveActions = const [],
}) {
  return SessionOutcome(
    sessionId: 'session-1',
    resolutionStatus: resolutionStatusFromCloseKind(closeKind),
    immediateCause: immediateCause,
    contributingFactors: contributingFactors,
    preventiveActions: preventiveActions,
    verified: verified,
    schemaVersion: '1.0',
    closeKind: closeKind,
    rootCause: rootCause,
    rankingLeaderLabel: rankingLeaderLabel,
    rankingLeaderFailureModeId: rankingLeaderFailureModeId,
    startSymptom: startSymptom,
    userNote: userNote,
    diyCostUsd: diyCostUsd,
  );
}
