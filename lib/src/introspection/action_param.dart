/// One parameter of an [ActionSpec].
class ActionParam {
  const ActionParam({
    required this.name,
    required this.type,
    this.required = true,
    this.enumValues,
  });

  final String name;

  /// One of: string, int, double, num, bool, datetime, enum, list, map, object, any.
  final String type;
  final bool required;

  /// Constant names, only when type == 'enum'.
  final List<String>? enumValues;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'type': type,
        if (!required) 'required': false,
        if (enumValues != null) 'enumValues': enumValues,
      };
}
