/// Maps household/app category ids and display labels onto Knowledge Graph slugs.
///
/// App packages use `washer` / `fridge`. The graph uses `washing-machine` /
/// `refrigerator-freezer`. Call this before any graph query keyed by family.
String kgGraphCategorySlug(String raw) {
  final key = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  return switch (key) {
    'washer' || 'washing-machine' || 'washingmachine' => 'washing-machine',
    'fridge' ||
    'refrigerator' ||
    'freezer' ||
    'refrigerator-freezer' ||
    'refrigerator/freezer' =>
      'refrigerator-freezer',
    'dishwasher' => 'dishwasher',
    'dryer' => 'dryer',
    _ => key,
  };
}
