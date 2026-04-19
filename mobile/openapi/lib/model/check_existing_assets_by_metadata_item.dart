//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CheckExistingAssetsByMetadataItem {
  /// Returns a new [CheckExistingAssetsByMetadataItem] instance.
  CheckExistingAssetsByMetadataItem({
    required this.fileCreatedAt,
    required this.height,
    required this.localId,
    required this.width,
  });

  /// File creation date (from EXIF or photo library)
  DateTime fileCreatedAt;

  /// Image/video height in pixels
  ///
  /// Maximum value: 9007199254740991
  int height;

  /// Local asset ID (client-side identifier)
  String localId;

  /// Image/video width in pixels
  ///
  /// Maximum value: 9007199254740991
  int width;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CheckExistingAssetsByMetadataItem &&
    other.fileCreatedAt == fileCreatedAt &&
    other.height == height &&
    other.localId == localId &&
    other.width == width;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fileCreatedAt.hashCode) +
    (height.hashCode) +
    (localId.hashCode) +
    (width.hashCode);

  @override
  String toString() => 'CheckExistingAssetsByMetadataItem[fileCreatedAt=$fileCreatedAt, height=$height, localId=$localId, width=$width]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'fileCreatedAt'] = _isEpochMarker(r'/^(?:(?:\\d\\d[2468][048]|\\d\\d[13579][26]|\\d\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\d|30)|(?:02)-(?:0[1-9]|1\\d|2[0-8])))T(?:(?:[01]\\d|2[0-3]):[0-5]\\d(?::[0-5]\\d(?:\\.\\d+)?)?(?:Z))$/')
        ? this.fileCreatedAt.millisecondsSinceEpoch
        : this.fileCreatedAt.toUtc().toIso8601String();
      json[r'height'] = this.height;
      json[r'localId'] = this.localId;
      json[r'width'] = this.width;
    return json;
  }

  /// Returns a new [CheckExistingAssetsByMetadataItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CheckExistingAssetsByMetadataItem? fromJson(dynamic value) {
    upgradeDto(value, "CheckExistingAssetsByMetadataItem");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return CheckExistingAssetsByMetadataItem(
        fileCreatedAt: mapDateTime(json, r'fileCreatedAt', r'/^(?:(?:\\d\\d[2468][048]|\\d\\d[13579][26]|\\d\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\d|30)|(?:02)-(?:0[1-9]|1\\d|2[0-8])))T(?:(?:[01]\\d|2[0-3]):[0-5]\\d(?::[0-5]\\d(?:\\.\\d+)?)?(?:Z))$/')!,
        height: mapValueOfType<int>(json, r'height')!,
        localId: mapValueOfType<String>(json, r'localId')!,
        width: mapValueOfType<int>(json, r'width')!,
      );
    }
    return null;
  }

  static List<CheckExistingAssetsByMetadataItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CheckExistingAssetsByMetadataItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CheckExistingAssetsByMetadataItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CheckExistingAssetsByMetadataItem> mapFromJson(dynamic json) {
    final map = <String, CheckExistingAssetsByMetadataItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CheckExistingAssetsByMetadataItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CheckExistingAssetsByMetadataItem-objects as value to a dart map
  static Map<String, List<CheckExistingAssetsByMetadataItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CheckExistingAssetsByMetadataItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CheckExistingAssetsByMetadataItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'fileCreatedAt',
    'height',
    'localId',
    'width',
  };
}

