// Fake v2 payloads (2026-11-28): the `catalog=1` index with categories and
// jar families, a BOM-only recipe, and the Tiramisu jar family.

Map<String, dynamic> _v2Recipe(
  String title, {
  required String category,
  String source = 'sop',
  String? headline,
  String status = 'approved',
  bool hasTrial = false,
  String? family,
  String? size,
  String? track,
  List<Map<String, dynamic>> versions = const [],
}) => {
  'key': title,
  'title': title,
  'item_code': title,
  'track': track,
  'status': status,
  'headline': headline,
  'has_trial': hasTrial,
  'updated': '2026-11-27 10:00:00',
  'versions': versions,
  'category': category,
  'family': family,
  'size': size,
  'has_method': versions.isNotEmpty,
  'source': source,
};

Map<String, dynamic> _v2Version(
  String name,
  int version, {
  String stage = 'Approved',
  String status = 'current',
}) => {
  'name': name,
  'version': version,
  'stage': stage,
  'status': status,
  'approved_on': stage == 'Approved' ? '2026-11-20' : null,
  'modified': '2026-11-20 10:00:00',
  'change_summary': null,
  'in_production': stage == 'Approved',
};

final Map<String, dynamic> kRecipeIndexV2Json = {
  'tracks': ['Standard line', 'Cookie jar line'],
  'categories': [
    {'key': 'bases', 'label': 'Cakes & biscuits'},
    {'key': 'fillings', 'label': 'Mixes & fillings'},
    {'key': 'jars', 'label': 'Jars'},
  ],
  'families': [
    {
      'family': 'Lotus',
      'track': null,
      'sizes': ['Small', 'Large'],
      'has_trial': true,
      'status': 'approved',
      'updated': '2026-11-27 10:00:00',
    },
    {
      'family': 'Tiramisu',
      'track': 'Standard line',
      'sizes': ['Small', 'Medium', 'Large'],
      'has_trial': false,
      'status': 'approved',
      'updated': '2026-11-27 10:00:00',
    },
  ],
  'recipes': [
    _v2Recipe(
      'Fudge Cake',
      category: 'bases',
      headline: 'SOP-0042',
      hasTrial: true,
      track: 'Standard line',
      versions: [_v2Version('SOP-0042', 4)],
    ),
    _v2Recipe('Sponge Cake', category: 'bases', source: 'bom'),
    _v2Recipe('Cheesecake Mix', category: 'fillings', source: 'bom'),
    _v2Recipe(
      'Chocolate ganache',
      category: 'fillings',
      headline: 'SOP-0070',
      versions: [_v2Version('SOP-0070', 1)],
    ),
    _v2Recipe(
      'Tiramisu Small',
      category: 'jars',
      family: 'Tiramisu',
      size: 'Small',
      track: 'Standard line',
      headline: 'SOP-0030',
      versions: [_v2Version('SOP-0030', 1)],
    ),
    _v2Recipe(
      'Tiramisu Medium',
      category: 'jars',
      family: 'Tiramisu',
      size: 'Medium',
      source: 'bom',
    ),
    _v2Recipe(
      'Tiramisu Large',
      category: 'jars',
      family: 'Tiramisu',
      size: 'Large',
      source: 'bom',
    ),
    _v2Recipe(
      'Lotus Large',
      category: 'jars',
      family: 'Lotus',
      size: 'Large',
      status: 'trial',
      headline: 'SOP-0080',
      versions: [_v2Version('SOP-0080', 1, stage: 'Trial', status: 'trial')],
    ),
    _v2Recipe(
      'Lotus Small',
      category: 'jars',
      family: 'Lotus',
      size: 'Small',
      source: 'bom',
    ),
    _v2Recipe(
      'Cookie jar second bake',
      category: 'jars',
      status: 'trial',
      headline: 'SOP-0090',
      track: 'Cookie jar line',
      versions: [_v2Version('SOP-0090', 2, stage: 'Trial', status: 'trial')],
    ),
  ],
};

/// A recipe read from a BOM alone (`get_recipe(item_code=...)`).
const Map<String, dynamic> kSpongeCakeBomJson = {
  'name': null,
  'key': 'Sponge Cake',
  'title': 'Sponge Cake',
  'item_code': 'Sponge Cake',
  'track': null,
  'version': null,
  'stage': null,
  'status': 'approved',
  'approved_on': null,
  'change_summary': null,
  'in_production': false,
  'equipment': '',
  'prep_time_mins': null,
  'notes': '',
  'yield': {'label': 'One batch', 'amount': 6.0, 'unit': 'Kg'},
  'ingredients': [
    {'key': 'flour', 'name': 'Flour', 'amount': 1500.0, 'unit': 'g'},
    {'key': 'eggs', 'name': 'Eggs', 'amount': 30, 'unit': 'piece'},
  ],
  'steps': [],
  'versions': [],
  'unresolved_tokens': [],
  'category': 'bases',
  'family': null,
  'size': null,
};

Map<String, dynamic> _layer(
  String name,
  List<double?> perSize, {
  String unit = 'g',
  List<String?>? items,
}) => {
  // The server keys a layer by the lowercased item code and names it as the
  // item is stored, which is often lowercase.
  'key': name.toLowerCase(),
  'name': name,
  'unit': unit,
  'per_jar': {
    for (var i = 0; i < 3; i++)
      if (perSize[i] != null) ['Small', 'Medium', 'Large'][i]: perSize[i],
  },
  if (items != null)
    'items': {
      for (var i = 0; i < 3; i++)
        if (items[i] != null) ['Small', 'Medium', 'Large'][i]: items[i],
    },
};

/// Tiramisu per jar, in grams. Large carries no powder sugar.
final Map<String, dynamic> kTiramisuFamilyJson = {
  'family': 'Tiramisu',
  'track': 'Standard line',
  'sizes': [
    {
      'size': 'Small',
      'item_code': 'Tiramisu Small',
      'title': 'Tiramisu Small',
      'sop': 'SOP-0030',
      'sop_version': 1,
      'status': 'approved',
      'jar_grams': 69.5,
    },
    {
      'size': 'Medium',
      'item_code': 'Tiramisu Medium',
      'title': 'Tiramisu Medium',
      'sop': null,
      'sop_version': null,
      'status': 'approved',
      'jar_grams': 139.0,
    },
    {
      'size': 'Large',
      'item_code': 'Tiramisu Large',
      'title': 'Tiramisu Large',
      'sop': 'SOP-0032',
      'sop_version': 1,
      'status': 'trial',
      'jar_grams': 221.4,
    },
  ],
  'layers': [
    _layer('savoiardi', [18.7, 37.4, 61.7]),
    _layer('cheesecake mix', [43.1, 86.2, 142.2]),
    _layer('coffee beans', [4.0, 8.0, 13.2]),
    _layer('powder sugar', [2.4, 4.8, null]),
    _layer('coco powder', [1.3, 2.6, 4.3]),
  ],
  'packaging': [
    _layer(
      'tiramisu jar label',
      [1, 1, 1],
      unit: 'Nos',
      items: ['tiramisu jar label 147', 'tiramisu label', null],
    ),
    _layer(
      'glass jar',
      [1, 1, 1],
      unit: 'Nos',
      items: ['glass jar 147', 'glass jar', 'glass jar 330'],
    ),
  ],
};

/// A family that exists in one size only.
final Map<String, dynamic> kCarrotFamilyJson = {
  'family': 'Carrot cake',
  'track': null,
  'sizes': [
    {
      'size': 'Medium',
      'item_code': 'Carrot cake jar (Medium)',
      'title': 'Carrot cake jar (Medium)',
      'sop': null,
      'sop_version': null,
      'status': 'approved',
      'jar_grams': 120.0,
    },
  ],
  'layers': [
    _layer('carrot sponge', [null, 120.0, null]),
  ],
  'packaging': [],
};
