import 'dart:convert';
import 'dart:io';

import 'package:modern_butlers_book/knowledge_factory/dryer_batch_01.dart';

void main() {
  final decoded = jsonDecode(dryerBatch01Json);
  final encoder = JsonEncoder.withIndent('  ');
  final out = File('lib/knowledge_factory/data/dryer_batch_01.v1.json');
  out.writeAsStringSync('${encoder.convert(decoded)}\n');
  final modes = (decoded as Map)['failureModes'] as List;
  stdout.writeln('Wrote ${out.path} with ${modes.length} modes');
}
