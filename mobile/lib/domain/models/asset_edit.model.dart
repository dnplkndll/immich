import "package:openapi/api.dart"
    show CropParameters, RotateParameters, MirrorParameters, AdjustParameters, FilterParameters;

enum AssetEditAction { rotate, crop, mirror, adjust, autoEnhance, filter, other }

sealed class AssetEdit {
  const AssetEdit();
}

class CropEdit extends AssetEdit {
  final CropParameters parameters;

  const CropEdit(this.parameters);
}

class RotateEdit extends AssetEdit {
  final RotateParameters parameters;

  const RotateEdit(this.parameters);
}

class MirrorEdit extends AssetEdit {
  final MirrorParameters parameters;

  const MirrorEdit(this.parameters);
}

class AdjustEdit extends AssetEdit {
  final AdjustParameters parameters;

  const AdjustEdit(this.parameters);
}

class AutoEnhanceEdit extends AssetEdit {
  const AutoEnhanceEdit();
}

class FilterEdit extends AssetEdit {
  final FilterParameters parameters;

  const FilterEdit(this.parameters);
}
