//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FilterParameters {
  /// Returns a new [FilterParameters] instance.
  FilterParameters({
    this.matrix = const [],
    required this.name,
  });

  /// Color matrix as a flat 4x5 array of 20 numbers (row-major)
  List<num> matrix;

  /// Name of the filter preset
  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FilterParameters &&
    _deepEquality.equals(other.matrix, matrix) &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (matrix.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'FilterParameters[matrix=$matrix, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'matrix'] = this.matrix;
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [FilterParameters] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FilterParameters? fromJson(dynamic value) {
    upgradeDto(value, "FilterParameters");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return FilterParameters(
        matrix: json[r'matrix'] is Iterable
            ? (json[r'matrix'] as Iterable).cast<num>().toList(growable: false)
            : const [],
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<FilterParameters> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FilterParameters>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FilterParameters.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FilterParameters> mapFromJson(dynamic json) {
    final map = <String, FilterParameters>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FilterParameters.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FilterParameters-objects as value to a dart map
  static Map<String, List<FilterParameters>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FilterParameters>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FilterParameters.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'matrix',
    'name',
  };
}

