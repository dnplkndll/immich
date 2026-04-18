import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/adjustments.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/presentation/pages/edit/editor.provider.dart';
import 'package:immich_ui/immich_ui.dart';

class AdjustPanel extends ConsumerWidget {
  const AdjustPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorNotifier = ref.read(editorStateProvider.notifier);
    final values = ref.watch(editorStateProvider.select((s) => s.adjustValues));
    final activeFilter = ref.watch(editorStateProvider.select((s) => s.activeFilterName));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
          child: Row(
            children: [
              ImmichTextButton(
                labelText: 'auto_enhance'.tr(),
                onPressed: editorNotifier.applyAutoEnhance,
                variant: ImmichVariant.ghost,
                expanded: false,
                icon: Icons.auto_fix_high,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: adjustPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = adjustPresets[index];
                final isSelected = activeFilter == preset.labelKey;
                return ChoiceChip(
                  label: Text(preset.labelKey.tr()),
                  selected: isSelected,
                  onSelected: (_) => editorNotifier.applyAdjustPreset(preset),
                  selectedColor: context.primaryColor.withValues(alpha: 0.3),
                  labelStyle: TextStyle(color: isSelected ? context.primaryColor : null, fontSize: 12),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _AdjustSlider(
                label: 'brightness'.tr(),
                value: values.brightness,
                onChanged: (v) => editorNotifier.setAdjustValues(values.copyWith(brightness: v)),
              ),
              _AdjustSlider(
                label: 'contrast'.tr(),
                value: values.contrast,
                onChanged: (v) => editorNotifier.setAdjustValues(values.copyWith(contrast: v)),
              ),
              _AdjustSlider(
                label: 'saturation'.tr(),
                value: values.saturation,
                onChanged: (v) => editorNotifier.setAdjustValues(values.copyWith(saturation: v)),
              ),
              _AdjustSlider(
                label: 'warmth'.tr(),
                value: values.warmth,
                onChanged: (v) => editorNotifier.setAdjustValues(values.copyWith(warmth: v)),
              ),
              _AdjustSlider(
                label: 'sharpness'.tr(),
                value: values.sharpness,
                onChanged: (v) => editorNotifier.setAdjustValues(values.copyWith(sharpness: v)),
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

  const _AdjustSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: context.textTheme.bodySmall)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
            child: Slider(value: value, min: -100, max: 100, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(value.round().toString(), style: context.textTheme.bodySmall, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
