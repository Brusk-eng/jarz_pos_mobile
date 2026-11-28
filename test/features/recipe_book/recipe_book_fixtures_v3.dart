// Fake v3 payloads (2026-11-28): jar layers, `can_edit`, and the editable form.

/// Tiramisu layers, grams per jar, Small / Medium / Large.
const Map<String, List<double>> kTiramisuLayers = {
  'Savoiardi': [18.7, 28.0, 40.0],
  'Coffee soak': [10.8, 16.2, 23.5],
  'Cream': [46.7, 70.0, 97.0],
  'Cocoa': [1.3, 2.0, 3.0],
};

const List<String> _sizes = ['Small', 'Medium', 'Large'];

Map<String, dynamic> _assemblyAligned() => {
  'aligned': true,
  'rows': [
    for (final e in kTiramisuLayers.entries)
      {
        'layer': e.key,
        'grams': {for (var i = 0; i < 3; i++) _sizes[i]: e.value[i]},
      },
  ],
  'by_size': {
    for (var i = 0; i < 3; i++)
      _sizes[i]: [
        for (final e in kTiramisuLayers.entries)
          {'layer': e.key, 'grams': e.value[i], 'note': null},
      ],
  },
  'totals': {'Small': 77.5, 'Medium': 116.2, 'Large': 163.5},
};

/// Small has an extra "Sprinkles" layer, so the sizes are not aligned.
Map<String, dynamic> _assemblyDiffering() => {
  'aligned': false,
  'rows': <Map<String, dynamic>>[],
  'by_size': {
    'Small': [
      {'layer': 'Savoiardi', 'grams': 18.7, 'note': null},
      {'layer': 'Sprinkles', 'grams': 2.0, 'note': null},
    ],
    'Medium': [
      {'layer': 'Savoiardi', 'grams': 28.0, 'note': null},
      {'layer': 'Cream', 'grams': 70.0, 'note': null},
    ],
  },
  'totals': {'Small': 20.7, 'Medium': 98.0},
};

/// The v2 Tiramisu family with v3 fields on top. Small and Large can change
/// where they stand; Medium cannot (it is on the Production Board).
Map<String, dynamic> kTiramisuFamilyV3Json(
  Map<String, dynamic> v2, {
  bool canEdit = true,
  Map<String, dynamic>? assembly,
}) => {
  ...v2,
  'can_edit': canEdit,
  'sizes': [
    for (final raw in (v2['sizes'] as List))
      {
        ...Map<String, dynamic>.from(raw as Map),
        'editable_in_place': raw['size'] != 'Medium',
      },
  ],
  'assembly': assembly ?? _assemblyAligned(),
};

Map<String, dynamic> kAssemblyAlignedJson() => _assemblyAligned();
Map<String, dynamic> kAssemblyDifferingJson() => _assemblyDiffering();
Map<String, dynamic> kAssemblyEmptyJson() => {
  'aligned': true,
  'rows': <Map<String, dynamic>>[],
  'by_size': <String, dynamic>{},
  'totals': <String, dynamic>{},
};

/// `get_recipe_for_edit` of an approved, table-source recipe that is already
/// used in production, so saving makes a new version.
const Map<String, dynamic> kFudgeEditFormJson = {
  'base': 'SOP-0042',
  'item_code': 'Fudge Cake',
  'title': 'Fudge Cake',
  'track': 'Standard line',
  'category': 'bases',
  'size': null,
  'family': null,
  'stage': 'Approved',
  'version': 4,
  'next_version': 5,
  'editable_in_place': false,
  'used_in_production': true,
  'ingredients_source': 'table',
  'ingredients': [
    {
      'name': 'Flour',
      'amount': 1500.0,
      'unit': 'g',
      'section': null,
      'note': null,
      'item_code': null,
    },
    {
      'name': 'Cocoa',
      'amount': 900.0,
      'unit': 'g',
      'section': null,
      'note': 'Sifted',
      'item_code': null,
    },
  ],
  'yield_qty': 14.29,
  'yield_uom': 'Kg',
  'prep_time_mins': 85,
  'equipment': 'Planetary mixer',
  'notes': 'Rest overnight.',
  'change_summary': 'More cocoa.',
  'layers': <Map<String, dynamic>>[],
  'steps': [
    {
      'title': 'Mix',
      'text': 'Sift [Flour] and [Cocoa].',
      'duration_mins': 10,
      'scaling_mode': 'Per Batch',
      'requires_confirmation': 0,
      'capture_type': null,
    },
  ],
  'token_map': {'[Flour]': '{{item:flour|grams}}'},
};

/// The same recipe, changeable where it stands (never used in production).
Map<String, dynamic> kFudgeEditInPlaceJson() => {
  ...kFudgeEditFormJson,
  'editable_in_place': true,
  'used_in_production': false,
};

/// A v3 `get_recipe`: Fudge Cake with layers and `can_edit`.
Map<String, dynamic> kFudgeV3Json(
  Map<String, dynamic> v1, {
  bool canEdit = true,
  String stage = 'Approved',
  List<Map<String, dynamic>> layers = const [],
}) => {
  ...v1,
  'can_edit': canEdit,
  'editable_in_place': false,
  'used_in_production': true,
  'stage': stage,
  'status': stage == 'Trial' ? 'trial' : 'current',
  'layers': layers,
  'versions': [
    {
      'name': 'SOP-0042',
      'version': 4,
      'stage': stage,
      'status': stage == 'Trial' ? 'trial' : 'current',
      'approved_on': null,
      'modified': '2026-11-20 10:00:00',
      'change_summary': null,
      'in_production': true,
    },
    if (stage == 'Trial')
      {
        'name': 'SOP-0040',
        'version': 3,
        'stage': 'Approved',
        'status': 'current',
        'approved_on': '2026-11-01',
        'modified': '2026-11-01 10:00:00',
        'change_summary': null,
        'in_production': true,
      },
  ],
};
