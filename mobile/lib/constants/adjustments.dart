import 'package:flutter/material.dart';

class AdjustValues {
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double sharpness;

  const AdjustValues({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.sharpness = 0,
  });

  bool get hasChanges => brightness != 0 || contrast != 0 || saturation != 0 || warmth != 0 || sharpness != 0;

  AdjustValues copyWith({double? brightness, double? contrast, double? saturation, double? warmth, double? sharpness}) {
    return AdjustValues(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      sharpness: sharpness ?? this.sharpness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdjustValues &&
        other.brightness == brightness &&
        other.contrast == contrast &&
        other.saturation == saturation &&
        other.warmth == warmth &&
        other.sharpness == sharpness;
  }

  @override
  int get hashCode =>
      brightness.hashCode ^ contrast.hashCode ^ saturation.hashCode ^ warmth.hashCode ^ sharpness.hashCode;
}

class AdjustPreset {
  /// The i18n key for the preset label (e.g. 'adjust_preset_vivid').
  final String labelKey;
  final AdjustValues values;

  const AdjustPreset({required this.labelKey, required this.values});
}

const List<AdjustPreset> adjustPresets = [
  AdjustPreset(labelKey: 'adjust_preset_original', values: AdjustValues()),
  AdjustPreset(
    labelKey: 'adjust_preset_vivid',
    values: AdjustValues(brightness: 5, contrast: 15, saturation: 40, sharpness: 10),
  ),
  AdjustPreset(
    labelKey: 'adjust_preset_dramatic',
    values: AdjustValues(brightness: -10, contrast: 40, saturation: -10, sharpness: 20),
  ),
  AdjustPreset(
    labelKey: 'adjust_preset_noir',
    values: AdjustValues(brightness: -5, contrast: 30, saturation: -100, sharpness: 15),
  ),
  AdjustPreset(labelKey: 'adjust_preset_mono', values: AdjustValues(contrast: 10, saturation: -100)),
  AdjustPreset(
    labelKey: 'adjust_preset_sepia',
    values: AdjustValues(brightness: 5, contrast: 5, saturation: -50, warmth: 40),
  ),
  AdjustPreset(
    labelKey: 'adjust_preset_warm',
    values: AdjustValues(brightness: 5, contrast: 5, saturation: 10, warmth: 30),
  ),
  AdjustPreset(labelKey: 'adjust_preset_cool', values: AdjustValues(contrast: 5, saturation: 5, warmth: -30)),
  AdjustPreset(
    labelKey: 'adjust_preset_vintage',
    values: AdjustValues(brightness: -5, contrast: -10, saturation: -30, warmth: 20),
  ),
  AdjustPreset(labelKey: 'adjust_preset_fade', values: AdjustValues(brightness: 10, contrast: -20, saturation: -20)),
];

const AdjustValues autoEnhanceValues = AdjustValues(
  brightness: 5,
  contrast: 15,
  saturation: 20,
  warmth: 5,
  sharpness: 10,
);

const double _lumR = 0.2126;
const double _lumG = 0.7152;
const double _lumB = 0.0722;

/// Builds a [ColorFilter] from adjustment slider values for live preview.
/// Each slider ranges from -100 to +100.
///
/// Sharpness is approximated as a local-contrast boost since true spatial
/// sharpening requires a convolution kernel beyond ColorFilter's capabilities.
ColorFilter adjustValuesToColorFilter(AdjustValues v) {
  var m = _identity();
  if (v.brightness != 0) m = _multiply(m, _brightnessMatrix(v.brightness));
  if (v.contrast != 0) m = _multiply(m, _contrastMatrix(v.contrast));
  if (v.saturation != 0) m = _multiply(m, _saturationMatrix(v.saturation));
  if (v.warmth != 0) m = _multiply(m, _warmthMatrix(v.warmth));
  if (v.sharpness != 0) m = _multiply(m, _sharpnessMatrix(v.sharpness));
  return ColorFilter.matrix(m);
}

List<double> _identity() {
  return <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

List<double> _brightnessMatrix(double slider) {
  final offset = slider / 100 * 50;
  return <double>[
    1, 0, 0, 0, offset, //
    0, 1, 0, 0, offset,
    0, 0, 1, 0, offset,
    0, 0, 0, 1, 0,
  ];
}

List<double> _contrastMatrix(double slider) {
  final f = 1.0 + slider / 100 * 0.5;
  final t = 128 * (1 - f);
  return <double>[
    f, 0, 0, 0, t, //
    0, f, 0, 0, t,
    0, 0, f, 0, t,
    0, 0, 0, 1, 0,
  ];
}

List<double> _saturationMatrix(double slider) {
  final s = 1.0 + slider / 100;
  final sr = (1 - s) * _lumR;
  final sg = (1 - s) * _lumG;
  final sb = (1 - s) * _lumB;
  return <double>[
    sr + s, sg, sb, 0, 0, //
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

List<double> _warmthMatrix(double slider) {
  final shift = slider / 100 * 25;
  return <double>[
    1, 0, 0, 0, shift, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, -shift,
    0, 0, 0, 1, 0,
  ];
}

List<double> _sharpnessMatrix(double slider) {
  final f = 1.0 + slider / 100 * 0.3;
  final t = 128 * (1 - f);
  return <double>[
    f, 0, 0, 0, t, //
    0, f, 0, 0, t,
    0, 0, f, 0, t,
    0, 0, 0, 1, 0,
  ];
}

List<double> _multiply(List<double> a, List<double> b) {
  final result = List<double>.filled(20, 0);
  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 5; col++) {
      double sum = 0;
      for (int k = 0; k < 4; k++) {
        sum += a[row * 5 + k] * b[k * 5 + col];
      }
      if (col == 4) {
        sum += a[row * 5 + 4];
      }
      result[row * 5 + col] = sum;
    }
  }
  for (int row = 0; row < 4; row++) {
    result[row * 5 + 4] = result[row * 5 + 4].clamp(-255, 255).toDouble();
  }
  return result;
}
