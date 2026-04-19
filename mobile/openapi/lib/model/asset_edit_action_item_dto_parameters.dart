//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssetEditActionItemDtoParameters {
  /// Returns a new [AssetEditActionItemDtoParameters] instance.
  AssetEditActionItemDtoParameters({
    required this.height,
    required this.width,
    required this.x,
    required this.y,
    required this.angle,
    required this.axis,
    this.brightness = 1,
    this.contrast = 1,
    this.hue = 0,
    this.saturation = 1,
    this.sharpness = 0,
    this.matrix = const [],
    required this.name,
  });

  /// Height of the crop
  ///
  /// Minimum value: 1
  num height;

  /// Width of the crop
  ///
  /// Minimum value: 1
  num width;

  /// Top-Left X coordinate of crop
  ///
  /// Minimum value: 0
  num x;

  /// Top-Left Y coordinate of crop
  ///
  /// Minimum value: 0
  num y;

  /// Rotation angle in degrees
  num angle;

  MirrorAxis axis;

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

  /// Color matrix as a flat 4x5 array of 20 numbers (row-major)
  List<num> matrix;

  /// Name of the filter preset
  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AssetEditActionItemDtoParameters &&
    other.height == height &&
    other.width == width &&
    other.x == x &&
    other.y == y &&
    other.angle == angle &&
    other.axis == axis &&
    other.brightness == brightness &&
    other.contrast == contrast &&
    other.hue == hue &&
    other.saturation == saturation &&
    other.sharpness == sharpness &&
    _deepEquality.equals(other.matrix, matrix) &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (height.hashCode) +
    (width.hashCode) +
    (x.hashCode) +
    (y.hashCode) +
    (angle.hashCode) +
    (axis.hashCode) +
    (brightness.hashCode) +
    (contrast.hashCode) +
    (hue.hashCode) +
    (saturation.hashCode) +
    (sharpness.hashCode) +
    (matrix.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'AssetEditActionItemDtoParameters[height=$height, width=$width, x=$x, y=$y, angle=$angle, axis=$axis, brightness=$brightness, contrast=$contrast, hue=$hue, saturation=$saturation, sharpness=$sharpness, matrix=$matrix, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'height'] = this.height;
      json[r'width'] = this.width;
      json[r'x'] = this.x;
      json[r'y'] = this.y;
      json[r'angle'] = this.angle;
      json[r'axis'] = this.axis;
      json[r'brightness'] = this.brightness;
      json[r'contrast'] = this.contrast;
      json[r'hue'] = this.hue;
      json[r'saturation'] = this.saturation;
      json[r'sharpness'] = this.sharpness;
      json[r'matrix'] = this.matrix;
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [AssetEditActionItemDtoParameters] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssetEditActionItemDtoParameters? fromJson(dynamic value) {
    upgradeDto(value, "AssetEditActionItemDtoParameters");
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      return AssetEditActionItemDtoParameters(
        height: num.parse('${json[r'height']}'),
        width: num.parse('${json[r'width']}'),
        x: num.parse('${json[r'x']}'),
        y: num.parse('${json[r'y']}'),
        angle: num.parse('${json[r'angle']}'),
        axis: MirrorAxis.fromJson(json[r'axis'])!,
        brightness: num.parse('${json[r'brightness']}'),
        contrast: num.parse('${json[r'contrast']}'),
        hue: num.parse('${json[r'hue']}'),
        saturation: num.parse('${json[r'saturation']}'),
        sharpness: num.parse('${json[r'sharpness']}'),
        matrix: json[r'matrix'] is Iterable
            ? (json[r'matrix'] as Iterable).cast<num>().toList(growable: false)
            : const [],
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<AssetEditActionItemDtoParameters> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AssetEditActionItemDtoParameters>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssetEditActionItemDtoParameters.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssetEditActionItemDtoParameters> mapFromJson(dynamic json) {
    final map = <String, AssetEditActionItemDtoParameters>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssetEditActionItemDtoParameters.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssetEditActionItemDtoParameters-objects as value to a dart map
  static Map<String, List<AssetEditActionItemDtoParameters>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AssetEditActionItemDtoParameters>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssetEditActionItemDtoParameters.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'height',
    'width',
    'x',
    'y',
    'angle',
    'axis',
    'matrix',
    'name',
  };
}

