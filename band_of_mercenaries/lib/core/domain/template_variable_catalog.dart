enum TemplateVariableType { string, integer, enumeration, boolean }

class TemplateVariableSpec {
  final String namespace;
  final String field;
  final TemplateVariableType type;

  const TemplateVariableSpec({
    required this.namespace,
    required this.field,
    required this.type,
  });

  String get key => '$namespace.$field';
}

class TemplateVariableCatalog {
  static const Set<String> namespaces = {'merc', 'quest', 'region', 'world', 'ally', 'enemy'};

  static const List<TemplateVariableSpec> entries = [
    // merc.* (9개)
    TemplateVariableSpec(namespace: 'merc', field: 'name',  type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'merc', field: 'job',   type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'merc', field: 'tier',  type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'level', type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'str',   type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'int',   type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'vit',   type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'agi',   type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'merc', field: 'state', type: TemplateVariableType.enumeration),

    // quest.* (10개)
    TemplateVariableSpec(namespace: 'quest', field: 'name',        type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'quest', field: 'type',        type: TemplateVariableType.enumeration),
    TemplateVariableSpec(namespace: 'quest', field: 'type_ko',     type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'quest', field: 'result',      type: TemplateVariableType.enumeration),
    TemplateVariableSpec(namespace: 'quest', field: 'difficulty',  type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'quest', field: 'reward_gold', type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'quest', field: 'net_profit',  type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'quest', field: 'enemy',       type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'quest', field: 'is_elite',    type: TemplateVariableType.boolean),
    TemplateVariableSpec(namespace: 'quest', field: 'elite_name',  type: TemplateVariableType.string),

    // region.* (6개 — sector_type 포함)
    TemplateVariableSpec(namespace: 'region', field: 'name',        type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'region', field: 'tier',        type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'region', field: 'tier_ko',     type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'region', field: 'sector',      type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'region', field: 'knowledge',   type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'region', field: 'sector_type', type: TemplateVariableType.string),

    // world.* (4개)
    TemplateVariableSpec(namespace: 'world', field: 'rank',            type: TemplateVariableType.enumeration),
    TemplateVariableSpec(namespace: 'world', field: 'rank_ko',         type: TemplateVariableType.string),
    TemplateVariableSpec(namespace: 'world', field: 'gold',            type: TemplateVariableType.integer),
    TemplateVariableSpec(namespace: 'world', field: 'joined_factions', type: TemplateVariableType.integer),

    // ally.* (1개)
    TemplateVariableSpec(namespace: 'ally', field: 'name', type: TemplateVariableType.string),

    // enemy.* (1개)
    TemplateVariableSpec(namespace: 'enemy', field: 'name', type: TemplateVariableType.string),
  ];

  static final Map<String, TemplateVariableSpec> _byKey = {
    for (final e in entries) e.key: e,
  };

  static TemplateVariableSpec? lookup(String namespace, String field) =>
      _byKey['$namespace.$field'];

  static bool isKnown(String namespace, String field) =>
      lookup(namespace, field) != null;
}
