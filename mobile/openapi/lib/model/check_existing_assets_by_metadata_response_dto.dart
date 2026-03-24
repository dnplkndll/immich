//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CheckExistingAssetsByMetadataResponseDto {
  /// Returns a new [CheckExistingAssetsByMetadataResponseDto] instance.
  CheckExistingAssetsByMetadataResponseDto({
    this.existingIdMap = const {},
  });

  /// Map of local asset ID to server asset UUID for matched assets
  Map<String, String> existingIdMap;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CheckExistingAssetsByMetadataResponseDto &&
    _deepEquality.equals(other.existingIdMap, existingIdMap);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (existingIdMap.hashCode);

  @override
  String toString() => 'CheckExistingAssetsByMetadataResponseDto[existingIdMap=$existingIdMap]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'existingIdMap'] = this.existingIdMap;
    return json;
  }

  /// Returns a new [CheckExistingAssetsByMetadataResponseDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CheckExistingAssetsByMetadataResponseDto? fromJson(dynamic value) {
    upgradeDto(value, "CheckExistingAssetsByMetadataResponseDto");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return CheckExistingAssetsByMetadataResponseDto(
        existingIdMap: mapCastOfType<String, String>(json, r'existingIdMap')!,
      );
    }
    return null;
  }

  static List<CheckExistingAssetsByMetadataResponseDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CheckExistingAssetsByMetadataResponseDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CheckExistingAssetsByMetadataResponseDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CheckExistingAssetsByMetadataResponseDto> mapFromJson(dynamic json) {
    final map = <String, CheckExistingAssetsByMetadataResponseDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CheckExistingAssetsByMetadataResponseDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CheckExistingAssetsByMetadataResponseDto-objects as value to a dart map
  static Map<String, List<CheckExistingAssetsByMetadataResponseDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CheckExistingAssetsByMetadataResponseDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CheckExistingAssetsByMetadataResponseDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'existingIdMap',
  };
}

