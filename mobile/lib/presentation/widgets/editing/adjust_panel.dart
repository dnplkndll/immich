import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:immich_mobile/constants/adjustments.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_ui/immich_ui.dart';

class AdjustPanel extends StatefulWidget {
  final AdjustValues initialValues;
  final ValueChanged<AdjustValues> onChanged;

  const AdjustPanel({
    super.key,
    this.initialValues = const AdjustValues(),
    required this.onChanged,
  });

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _warmth;
  late double _sharpness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.initialValues.brightness;
    _contrast = widget.initialValues.contrast;
    _saturation = widget.initialValues.saturation;
    _warmth = widget.initialValues.warmth;
    _sharpness = widget.initialValues.sharpness;
  }

  AdjustValues get _currentValues => AdjustValues(
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        warmth: _warmth,
        sharpness: _sharpness,
      );

  void _applyPreset(AdjustValues values) {
    setState(() {
      _brightness = values.brightness;
      _contrast = values.contrast;
      _saturation = values.saturation;
      _warmth = values.warmth;
      _sharpness = values.sharpness;
    });
    widget.onChanged(_currentValues);
  }

  void _applyAutoEnhance() {
    _applyPreset(autoEnhanceValues);
  }

  void _updateSlider(void Function() update) {
    setState(update);
    widget.onChanged(_currentValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Auto-enhance button
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
          child: Row(
            children: [
              ImmichTextButton(
                labelText: 'auto_enhance'.tr(),
                onPressed: _applyAutoEnhance,
                variant: ImmichVariant.ghost,
                expanded: false,
                icon: Icons.auto_fix_high,
              ),
            ],
          ),
        ),
        // Preset strip
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: adjustPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = adjustPresets[index];
                final isSelected = _currentValues.brightness == preset.values.brightness &&
                    _currentValues.contrast == preset.values.contrast &&
                    _currentValues.saturation == preset.values.saturation &&
                    _currentValues.warmth == preset.values.warmth &&
                    _currentValues.sharpness == preset.values.sharpness;
                return ChoiceChip(
                  label: Text(preset.labelKey.tr()),
                  selected: isSelected,
                  onSelected: (_) => _applyPreset(preset.values),
                  selectedColor: context.primaryColor.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? context.primaryColor : null,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        // Sliders
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _AdjustSlider(
                label: 'brightness'.tr(),
                value: _brightness,
                onChanged: (v) => _updateSlider(() => _brightness = v),
              ),
              _AdjustSlider(
                label: 'contrast'.tr(),
                value: _contrast,
                onChanged: (v) => _updateSlider(() => _contrast = v),
              ),
              _AdjustSlider(
                label: 'saturation'.tr(),
                value: _saturation,
                onChanged: (v) => _updateSlider(() => _saturation = v),
              ),
              _AdjustSlider(
                label: 'warmth'.tr(),
                value: _warmth,
                onChanged: (v) => _updateSlider(() => _warmth = v),
              ),
              _AdjustSlider(
                label: 'sharpness'.tr(),
                value: _sharpness,
                onChanged: (v) => _updateSlider(() => _sharpness = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: -100,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
