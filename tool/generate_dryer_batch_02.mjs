import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const py = readFileSync(join(root, 'tool/generate_dryer_batch_02.py'), 'utf8');
const match = py.match(/MODES = \[([\s\S]*?)\]\n\nassert len\(MODES\)/);
if (!match) throw new Error('Could not parse MODES from python file');
const modes = eval('(' + match[1].replace(/True/g, 'true').replace(/False/g, 'false') + ')');
for (const mode of modes) {
  mode.schemaVersion = '1.0';
  mode.applianceFamily = 'dryer';
}
const document = {
  schemaVersion: '1.0',
  batchId: 'dryer-batch-02',
  applianceFamily: 'dryer',
  failureModes: modes,
};

function dartString(value) {
  return JSON.stringify(value);
}

function emitList(items, indent = 4) {
  const sp = ' '.repeat(indent);
  const lines = ['['];
  for (const item of items) {
    if (typeof item === 'object' && item !== null && !Array.isArray(item)) {
      lines.push(`${sp}${emitMap(item, indent + 2)},`);
    } else if (typeof item === 'string') {
      lines.push(`${sp}${dartString(item)},`);
    } else {
      lines.push(`${sp}${JSON.stringify(item)},`);
    }
  }
  lines.push(' '.repeat(indent - 2) + ']');
  return lines.join('\n');
}

function emitMap(obj, indent = 2) {
  const sp = ' '.repeat(indent);
  const lines = ['{'];
  for (const [key, value] of Object.entries(obj)) {
    let rendered;
    if (typeof value === 'string') rendered = dartString(value);
    else if (typeof value === 'boolean') rendered = value ? 'true' : 'false';
    else if (Array.isArray(value)) rendered = emitList(value, indent + 2);
    else rendered = JSON.stringify(value);
    lines.push(`${sp}'${key}': ${rendered},`);
  }
  lines.push(' '.repeat(indent - 2) + '}');
  return lines.join('\n');
}

const header = `import 'dart:convert';

/// Dryer Knowledge Factory Batch 02 — twenty additional failure modes.
///
/// Source maps mirror [data/dryer_batch_02.v1.json]. Prefer editing the JSON
/// data file, then regenerating this embedding, or keep both aligned via tests.
const String dryerBatch02Id = 'dryer-batch-02';
const String dryerBatch02SchemaVersion = '1.0';

/// Embedded Batch 02 JSON document (\`{ "batchId", "failureModes": [...] }\`).
String get dryerBatch02Json => jsonEncode(_dryerBatch02Document);

const Map<String, Object?> _dryerBatch02Document = {
  'schemaVersion': dryerBatch02SchemaVersion,
  'batchId': dryerBatch02Id,
  'applianceFamily': 'dryer',
  'failureModes': _dryerBatch02Modes,
};

const List<Map<String, Object?>> _dryerBatch02Modes = [
`;

const dart = header + modes.map((m) => emitMap(m, 4)).join(',\n') + '\n];\n';
writeFileSync(join(root, 'lib/knowledge_factory/data/dryer_batch_02.v1.json'), JSON.stringify(document, null, 2) + '\n');
writeFileSync(join(root, 'lib/knowledge_factory/dryer_batch_02.dart'), dart);
console.log('Wrote batch 02 files', modes.length, 'modes');
