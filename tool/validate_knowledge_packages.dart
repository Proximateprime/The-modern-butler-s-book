import 'dart:io';

import 'package:modern_butlers_book/helpers/package_release_validator.dart';

/// CI-less knowledge package gates. Does not publish.
void main(List<String> args) {
  final root = args.isNotEmpty ? args.first : findRepoRoot();
  final report = validateKnowledgePackages(repoRoot: root);
  for (final note in report.notes) {
    stdout.writeln(note);
  }
  if (report.ok) {
    stdout.writeln('VALIDATOR OK');
    return;
  }
  stderr.writeln('VALIDATOR FAILED');
  for (final error in report.errors) {
    stderr.writeln(error);
  }
  exitCode = 1;
}
