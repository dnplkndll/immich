import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/adjustments.dart';
import 'package:immich_mobile/domain/models/asset_edit.model.dart';
import 'package:immich_mobile/domain/models/exif.model.dart';
import 'package:immich_mobile/utils/editor.utils.dart';

final editorStateProvider = NotifierProvider<EditorProvider, EditorState>(EditorProvider.new);

class EditorProvider extends Notifier<EditorState> {
  @override
  EditorState build() {
    return const EditorState();
  }

  void clear() {
    state = const EditorState();
  }

  void init(List<AssetEdit> edits, ExifInfo exifInfo) {
    clear();

    final existingCrop = edits.whereType<CropEdit>().firstOrNull;
    final existingAdjust = edits.whereType<AdjustEdit>().firstOrNull;
    final hasAutoEnhance = edits.whereType<AutoEnhanceEdit>().isNotEmpty;

    final originalWidth = exifInfo.isFlipped ? exifInfo.height : exifInfo.width;
    final originalHeight = exifInfo.isFlipped ? exifInfo.width : exifInfo.height;

    Rect crop = existingCrop != null && originalWidth != null && originalHeight != null
        ? convertCropParametersToRect(existingCrop.parameters, originalWidth, originalHeight)
        : const Rect.fromLTRB(0, 0, 1, 1);

    final transform = normalizeTransformEdits(edits);

    state = state.copyWith(
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      crop: crop,
      flipHorizontal: transform.mirrorHorizontal,
      flipVertical: transform.mirrorVertical,
      adjustValues: existingAdjust != null ? _adjustValuesFromServer(existingAdjust) : null,
      isAutoEnhance: hasAutoEnhance,
    );

    _animateRotation(transform.rotation.toInt(), duration: Duration.zero);
  }

  static AdjustValues _adjustValuesFromServer(AdjustEdit edit) {
    final p = edit.parameters;
    final sharpness = p.sharpness.toDouble() / 2 * 100;
    return AdjustValues(
      brightness: (p.brightness.toDouble() - 1) * 100,
      contrast: (p.contrast.toDouble() - 1) * 100,
      saturation: (p.saturation.toDouble() - 1) * 100,
      warmth: hueToWarmth(p.hue.toDouble()).clamp(-100.0, 100.0),
      sharpness: sharpness.clamp(0.0, 100.0),
    );
  }

  void _animateRotation(int angle, {Duration duration = const Duration(milliseconds: 300)}) {
    state = state.copyWith(rotationAngle: angle, animationDuration: duration);
  }

  void normalizeRotation() {
    final normalizedAngle = ((state.rotationAngle % 360) + 360) % 360;
    if (normalizedAngle != state.rotationAngle) {
      state = state.copyWith(rotationAngle: normalizedAngle, animationDuration: Duration.zero);
    }
  }

  void setIsEditing(bool isApplyingEdits) {
    state = state.copyWith(isApplyingEdits: isApplyingEdits);
  }

  void setCrop(Rect crop) {
    state = state.copyWith(crop: crop, hasUnsavedEdits: true);
  }

  void setAspectRatio(double? aspectRatio) {
    if (aspectRatio != null && state.rotationAngle % 180 != 0) {
      // When rotated 90 or 270 degrees, swap width and height for aspect ratio calculations
      aspectRatio = 1 / aspectRatio;
    }

    state = state.copyWith(aspectRatio: aspectRatio);
  }

  void resetEdits() {
    _animateRotation(0);

    state = state.copyWith(
      flipHorizontal: false,
      flipVertical: false,
      crop: const Rect.fromLTRB(0, 0, 1, 1),
      aspectRatio: null,
      hasUnsavedEdits: true,
    );
  }

  void rotateCCW() {
    _animateRotation(state.rotationAngle - 90);
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void rotateCW() {
    _animateRotation(state.rotationAngle + 90);
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void flipHorizontally() {
    if (state.rotationAngle % 180 != 0) {
      // When rotated 90 or 270 degrees, flipping horizontally is equivalent to flipping vertically
      state = state.copyWith(flipVertical: !state.flipVertical, hasUnsavedEdits: true);
    } else {
      state = state.copyWith(flipHorizontal: !state.flipHorizontal, hasUnsavedEdits: true);
    }
  }

  void flipVertically() {
    if (state.rotationAngle % 180 != 0) {
      // When rotated 90 or 270 degrees, flipping vertically is equivalent to flipping horizontally
      state = state.copyWith(flipHorizontal: !state.flipHorizontal, hasUnsavedEdits: true);
    } else {
      state = state.copyWith(flipVertical: !state.flipVertical, hasUnsavedEdits: true);
    }
  }

  void setAdjustValues(AdjustValues values) {
    state = state.copyWith(adjustValues: values, isAutoEnhance: false, activeFilterName: null, hasUnsavedEdits: true);
  }

  void applyAdjustPreset(AdjustPreset preset) {
    state = state.copyWith(
      adjustValues: preset.values,
      isAutoEnhance: false,
      activeFilterName: preset.labelKey,
      hasUnsavedEdits: true,
    );
  }

  void applyAutoEnhance() {
    state = state.copyWith(
      adjustValues: autoEnhanceValues,
      isAutoEnhance: true,
      activeFilterName: null,
      hasUnsavedEdits: true,
    );
  }

  void resetAdjustments() {
    state = state.copyWith(
      adjustValues: const AdjustValues(),
      isAutoEnhance: false,
      activeFilterName: null,
      hasUnsavedEdits: true,
    );
  }
}

class EditorState {
  final bool isApplyingEdits;

  final int rotationAngle;
  final bool flipHorizontal;
  final bool flipVertical;
  final Rect crop;
  final double? aspectRatio;

  final int originalWidth;
  final int originalHeight;

  final Duration animationDuration;

  final bool hasUnsavedEdits;

  final AdjustValues adjustValues;
  final bool isAutoEnhance;
  final String? activeFilterName;

  const EditorState({
    bool? isApplyingEdits,
    int? rotationAngle,
    bool? flipHorizontal,
    bool? flipVertical,
    Rect? crop,
    this.aspectRatio,
    int? originalWidth,
    int? originalHeight,
    Duration? animationDuration,
    bool? hasUnsavedEdits,
    AdjustValues? adjustValues,
    bool? isAutoEnhance,
    this.activeFilterName,
  }) : isApplyingEdits = isApplyingEdits ?? false,
       rotationAngle = rotationAngle ?? 0,
       flipHorizontal = flipHorizontal ?? false,
       flipVertical = flipVertical ?? false,
       animationDuration = animationDuration ?? Duration.zero,
       originalWidth = originalWidth ?? 0,
       originalHeight = originalHeight ?? 0,
       crop = crop ?? const Rect.fromLTRB(0, 0, 1, 1),
       hasUnsavedEdits = hasUnsavedEdits ?? false,
       adjustValues = adjustValues ?? const AdjustValues(),
       isAutoEnhance = isAutoEnhance ?? false;

  EditorState copyWith({
    bool? isApplyingEdits,
    int? rotationAngle,
    bool? flipHorizontal,
    bool? flipVertical,
    double? aspectRatio = double.infinity,
    int? originalWidth,
    int? originalHeight,
    Duration? animationDuration,
    Rect? crop,
    bool? hasUnsavedEdits,
    AdjustValues? adjustValues,
    bool? isAutoEnhance,
    Object? activeFilterName = _sentinel,
  }) {
    return EditorState(
      isApplyingEdits: isApplyingEdits ?? this.isApplyingEdits,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      aspectRatio: aspectRatio == double.infinity ? this.aspectRatio : aspectRatio,
      animationDuration: animationDuration ?? this.animationDuration,
      originalWidth: originalWidth ?? this.originalWidth,
      originalHeight: originalHeight ?? this.originalHeight,
      crop: crop ?? this.crop,
      hasUnsavedEdits: hasUnsavedEdits ?? this.hasUnsavedEdits,
      adjustValues: adjustValues ?? this.adjustValues,
      isAutoEnhance: isAutoEnhance ?? this.isAutoEnhance,
      activeFilterName: identical(activeFilterName, _sentinel) ? this.activeFilterName : activeFilterName as String?,
    );
  }

  bool get hasEdits {
    return rotationAngle != 0 ||
        flipHorizontal ||
        flipVertical ||
        crop != const Rect.fromLTRB(0, 0, 1, 1) ||
        adjustValues.hasChanges ||
        isAutoEnhance;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditorState &&
        other.isApplyingEdits == isApplyingEdits &&
        other.rotationAngle == rotationAngle &&
        other.flipHorizontal == flipHorizontal &&
        other.flipVertical == flipVertical &&
        other.crop == crop &&
        other.aspectRatio == aspectRatio &&
        other.originalWidth == originalWidth &&
        other.originalHeight == originalHeight &&
        other.animationDuration == animationDuration &&
        other.hasUnsavedEdits == hasUnsavedEdits &&
        other.adjustValues == adjustValues &&
        other.isAutoEnhance == isAutoEnhance &&
        other.activeFilterName == activeFilterName;
  }

  @override
  int get hashCode {
    return isApplyingEdits.hashCode ^
        rotationAngle.hashCode ^
        flipHorizontal.hashCode ^
        flipVertical.hashCode ^
        crop.hashCode ^
        aspectRatio.hashCode ^
        originalWidth.hashCode ^
        originalHeight.hashCode ^
        animationDuration.hashCode ^
        hasUnsavedEdits.hashCode ^
        adjustValues.hashCode ^
        isAutoEnhance.hashCode ^
        activeFilterName.hashCode;
  }
}

const _sentinel = Object();
