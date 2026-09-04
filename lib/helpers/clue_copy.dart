/// One household word for session progress. Display only.
String householdClueSummary(int clueCount) {
  if (clueCount <= 0) {
    return 'No clues yet';
  }
  if (clueCount == 1) {
    return '1 clue';
  }
  return '$clueCount clues';
}
