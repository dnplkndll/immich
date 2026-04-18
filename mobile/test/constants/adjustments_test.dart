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
    test('returns a ColorFilter for identity values', () {
      final filter = adjustValuesToColorFilter(const AdjustValues());
      expect(filter, isA<ColorFilter>());
    });

    test('returns distinct filters for distinct values', () {
      final identity = adjustValuesToColorFilter(const AdjustValues());
      final shifted = adjustValuesToColorFilter(const AdjustValues(brightness: 50));
      expect(identity, isNot(equals(shifted)));
    });
  });

  test('autoEnhanceValues has non-zero brightness/contrast', () {
    expect(autoEnhanceValues.brightness, greaterThan(0));
    expect(autoEnhanceValues.contrast, greaterThan(0));
  });
}
