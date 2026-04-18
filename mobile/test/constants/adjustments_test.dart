import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/constants/adjustments.dart';

void main() {
  group('AdjustValues', () {
    test('defaults to zero across all sliders', () {
      const v = AdjustValues();
      expect(v.brightness, 0);
      expect(v.contrast, 0);
      expect(v.saturation, 0);
      expect(v.warmth, 0);
      expect(v.sharpness, 0);
      expect(v.hasChanges, isFalse);
    });

    test('hasChanges is true when any slider is non-zero', () {
      expect(const AdjustValues(brightness: 1).hasChanges, isTrue);
      expect(const AdjustValues(contrast: -1).hasChanges, isTrue);
      expect(const AdjustValues(saturation: 0.5).hasChanges, isTrue);
      expect(const AdjustValues(warmth: -0.5).hasChanges, isTrue);
      expect(const AdjustValues(sharpness: 1).hasChanges, isTrue);
    });

    test('copyWith overrides only the given fields', () {
      const base = AdjustValues(brightness: 10, contrast: 20);
      final copy = base.copyWith(contrast: 30);
      expect(copy.brightness, 10);
      expect(copy.contrast, 30);
    });

    test('equality is value-based', () {
      expect(const AdjustValues(brightness: 5), const AdjustValues(brightness: 5));
      expect(const AdjustValues(brightness: 5), isNot(const AdjustValues(brightness: 6)));
    });
  });

  group('adjustPresets', () {
    test('first preset is identity (no changes)', () {
      expect(adjustPresets.first.labelKey, 'adjust_preset_original');
      expect(adjustPresets.first.values.hasChanges, isFalse);
    });

    test('all preset labelKeys are unique', () {
      final keys = adjustPresets.map((p) => p.labelKey).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('non-original presets all have changes', () {
      for (final preset in adjustPresets.skip(1)) {
        expect(preset.values.hasChanges, isTrue, reason: 'preset ${preset.labelKey} should alter values');
      }
    });
  });

  group('adjustValuesToColorFilter', () {
    test('identity AdjustValues produces identity ColorFilter.matrix', () {
      final filter = adjustValuesToColorFilter(const AdjustValues());
      expect(
        filter,
        equals(
          const ColorFilter.matrix(<double>[
            1, 0, 0, 0, 0, //
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
        ),
      );
    });

    test('returns distinct filters for distinct values', () {
      final identity = adjustValuesToColorFilter(const AdjustValues());
      final shifted = adjustValuesToColorFilter(const AdjustValues(brightness: 50));
      expect(identity, isNot(equals(shifted)));
    });
  });

  group('warmth <-> hue mapping', () {
    test('warmth 0 is hue 0', () {
      expect(warmthToHue(0), 0);
    });

    test('warmth +100 maps to 30 degrees and back', () {
      expect(warmthToHue(100), 30);
      expect(hueToWarmth(30), closeTo(100, 1e-9));
    });

    test('warmth -100 maps to 330 degrees and back', () {
      expect(warmthToHue(-100), 330);
      expect(hueToWarmth(330), closeTo(-100, 1e-9));
    });

    test('round-trip preserves value across the warm/cool band', () {
      for (final warmth in [-100.0, -50.0, -1.0, 0.0, 1.0, 50.0, 100.0]) {
        final hue = warmthToHue(warmth);
        expect(hueToWarmth(hue), closeTo(warmth, 1e-9), reason: 'warmth=$warmth hue=$hue');
      }
    });

    test('hue outside the warm/cool bands is treated as neutral', () {
      expect(hueToWarmth(90), 0);
      expect(hueToWarmth(180), 0);
      expect(hueToWarmth(329), 0);
    });
  });

  group('forward slider mappings', () {
    test('sliderToMultiplier is 1.0 at 0', () {
      expect(sliderToMultiplier(0), 1.0);
      expect(sliderToMultiplier(100), 2.0);
      expect(sliderToMultiplier(-100), 0.0);
    });

    test('sliderToSharpness clamps negatives to 0', () {
      expect(sliderToSharpness(-50), 0);
      expect(sliderToSharpness(0), 0);
      expect(sliderToSharpness(50), 1.0);
      expect(sliderToSharpness(100), 2.0);
    });
  });

  test('autoEnhanceValues has non-zero brightness/contrast', () {
    expect(autoEnhanceValues.brightness, greaterThan(0));
    expect(autoEnhanceValues.contrast, greaterThan(0));
  });
}
