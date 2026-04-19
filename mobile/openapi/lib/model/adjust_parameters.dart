//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AdjustParameters {
  /// Returns a new [AdjustParameters] instance.
  AdjustParameters({
    this.brightness = 1,
    this.contrast = 1,
    this.hue = 0,
    this.saturation = 1,
    this.sharpness = 0,
  });

  /// Brightness multiplier (1.0 = no change)
  ///
  /// Minimum value: 0
  /// Maximum value: 2
  num brightness;

  /// Contrast multiplier (1.0 = no change)
  ///
  /// Minimum value: 0
  /// Maximum value: 2
  num contrast;

  /// Hue rotation in degrees (0 = no change)
  ///
  /// Minimum value: 0
  /// Maximum value: 360
  num hue;

  /// Saturation multiplier (1.0 = no change)
  ///
  /// Minimum value: 0
  /// Maximum value: 2
  num saturation;

  /// Sharpness sigma (0 = no sharpening)
  ///
  /// Minimum value: 0
  /// Maximum value: 2
  num sharpness;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AdjustParameters &&
    other.brightness == brightness &&
    other.contrast == contrast &&
    other.hue == hue &&
    other.saturation == saturation &&
    other.sharpness == sharpness;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (brightness.hashCode) +
    (contrast.hashCode) +
    (hue.hashCode) +
    (saturation.hashCode) +
    (sharpness.hashCode);

  @override
  String toString() => 'AdjustParameters[brightness=$brightness, contrast=$contrast, hue=$hue, saturation=$saturation, sharpness=$sharpness]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'brightness'] = this.brightness;
      json[r'contrast'] = this.contrast;
      json[r'hue'] = this.hue;
      json[r'saturation'] = this.saturation;
      json[r'sharpness'] = this.sharpness;
    return json;
  }

  /// Returns a new [AdjustParameters] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AdjustParameters? fromJson(dynamic value) {
    upgradeDto(value, "AdjustParameters");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return AdjustParameters(
        brightness: num.parse('${json[r'brightness']}'),
        contrast: num.parse('${json[r'contrast']}'),
        hue: num.parse('${json[r'hue']}'),
        saturation: num.parse('${json[r'saturation']}'),
        sharpness: num.parse('${json[r'sharpness']}'),
      );
    }
    return null;
  }

  static List<AdjustParameters> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AdjustParameters>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AdjustParameters.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AdjustParameters> mapFromJson(dynamic json) {
    final map = <String, AdjustParameters>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AdjustParameters.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AdjustParameters-objects as value to a dart map
  static Map<String, List<AdjustParameters>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AdjustParameters>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AdjustParameters.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

