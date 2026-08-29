// Run: dart run tool/export_batch_02_json.dart > lib/knowledge_factory/data/dryer_batch_02.v1.json
import 'dart:convert';
import 'package:modern_butlers_book/knowledge_factory/dryer_batch_02.dart';

void main() {
  final decoded = jsonDecode(dryerBatch02Json);
  print(const JsonEncoder.withIndent('  ').convert(decoded));
}
