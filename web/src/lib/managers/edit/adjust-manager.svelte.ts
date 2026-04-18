import { type EditActions, type EditToolManager } from '$lib/managers/edit/edit-manager.svelte';
import type { AssetResponseDto } from '@immich/sdk';

export interface AdjustValues {
  brightness: number;
  contrast: number;
  saturation: number;
  warmth: number;
  sharpness: number;
}

export interface FilterPreset {
  name: string;
  label: string;
  values: AdjustValues;
}

const defaultValues: AdjustValues = {
  brightness: 0,
  contrast: 0,
  saturation: 0,
  warmth: 0,
  sharpness: 0,
};

export const filterPresets: FilterPreset[] = [
  {
    name: 'original',
    label: 'Original',
    values: { brightness: 0, contrast: 0, saturation: 0, warmth: 0, sharpness: 0 },
  },
  { name: 'vivid', label: 'Vivid', values: { brightness: 5, contrast: 15, saturation: 40, warmth: 0, sharpness: 10 } },
  {
    name: 'dramatic',
    label: 'Dramatic',
    values: { brightness: -10, contrast: 40, saturation: -10, warmth: 0, sharpness: 20 },
  },
  { name: 'noir', label: 'Noir', values: { brightness: -5, contrast: 30, saturation: -100, warmth: 0, sharpness: 15 } },
  { name: 'mono', label: 'Mono', values: { brightness: 0, contrast: 10, saturation: -100, warmth: 0, sharpness: 0 } },
  { name: 'sepia', label: 'Sepia', values: { brightness: 5, contrast: 5, saturation: -50, warmth: 40, sharpness: 0 } },
  { name: 'warm', label: 'Warm', values: { brightness: 5, contrast: 5, saturation: 10, warmth: 30, sharpness: 0 } },
  { name: 'cool', label: 'Cool', values: { brightness: 0, contrast: 5, saturation: 5, warmth: -30, sharpness: 0 } },
  {
    name: 'vintage',
    label: 'Vintage',
    values: { brightness: -5, contrast: -10, saturation: -30, warmth: 20, sharpness: 0 },
  },
  { name: 'fade', label: 'Fade', values: { brightness: 10, contrast: -20, saturation: -20, warmth: 0, sharpness: 0 } },
];

// Map UI slider values (-100..+100) onto the server's sharp parameter ranges.
// brightness/contrast/saturation: 0.0 to 2.0 (1.0 = identity)
// sharpness: 0 to 2 sigma (0 = no sharpen)
// warmth: approximated via hue rotation degrees (warm = slight positive, cool = negative wrap)
const sliderToServerBrightness = (v: number) => 1 + v / 100;
const sliderToServerContrast = (v: number) => 1 + v / 100;
const sliderToServerSaturation = (v: number) => 1 + v / 100;
const sliderToServerSharpness = (v: number) => Math.max(0, v / 50);
const sliderToServerHue = (warmth: number) =>
  warmth >= 0 ? Math.round((warmth / 100) * 30) : Math.round(360 + (warmth / 100) * 30);

// Build a live-preview CSS filter string matching the server's sharp pipeline as
// closely as the browser allows. Warmth is approximated with sepia()/hue-rotate().
export const cssFilterForAdjustValues = (v: AdjustValues): string => {
  const b = sliderToServerBrightness(v.brightness);
  const c = sliderToServerContrast(v.contrast);
  const s = sliderToServerSaturation(v.saturation);
  const warm = v.warmth > 0 ? `sepia(${(v.warmth / 100) * 0.3})` : '';
  const cool = v.warmth < 0 ? `hue-rotate(${Math.round((v.warmth / 100) * 30)}deg)` : '';
  return `brightness(${b}) contrast(${c}) saturate(${s}) ${warm} ${cool}`.replace(/\s+/g, ' ').trim();
};

class AdjustManager implements EditToolManager {
  hasChanges: boolean = $state(false);
  canReset: boolean = $derived.by(() => this.checkHasEdits());

  brightness = $state(0);
  contrast = $state(0);
  saturation = $state(0);
  warmth = $state(0);
  sharpness = $state(0);
  isAutoEnhance = $state(false);
  activeFilter = $state('original');

  edits = $derived.by(() => this.getEdits());

  cssFilter = $derived.by(() =>
    cssFilterForAdjustValues({
      brightness: this.brightness,
      contrast: this.contrast,
      saturation: this.saturation,
      warmth: this.warmth,
      sharpness: this.sharpness,
    }),
  );

  private checkHasEdits(): boolean {
    return (
      this.brightness !== 0 ||
      this.contrast !== 0 ||
      this.saturation !== 0 ||
      this.warmth !== 0 ||
      this.sharpness !== 0 ||
      this.isAutoEnhance
    );
  }

  private getEdits(): EditActions {
    if (this.isAutoEnhance) {
      return [{ action: 'auto-enhance' as never, parameters: {} as never }];
    }

    if (!this.checkHasEdits()) {
      return [];
    }

    return [
      {
        action: 'adjust' as never,
        parameters: {
          brightness: sliderToServerBrightness(this.brightness),
          contrast: sliderToServerContrast(this.contrast),
          saturation: sliderToServerSaturation(this.saturation),
          hue: sliderToServerHue(this.warmth),
          sharpness: sliderToServerSharpness(this.sharpness),
        } as never,
      },
    ];
  }

  applyPreset(preset: FilterPreset) {
    this.activeFilter = preset.name;
    this.brightness = preset.values.brightness;
    this.contrast = preset.values.contrast;
    this.saturation = preset.values.saturation;
    this.warmth = preset.values.warmth;
    this.sharpness = preset.values.sharpness;
    this.isAutoEnhance = false;
    this.hasChanges = preset.name !== 'original';
  }

  setAutoEnhance() {
    this.isAutoEnhance = true;
    this.activeFilter = '';
    this.hasChanges = true;
  }

  setValue(key: keyof AdjustValues, value: number) {
    this[key] = value;
    this.isAutoEnhance = false;
    this.activeFilter = '';
    this.hasChanges = true;
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async onActivate(_asset: AssetResponseDto, edits: EditActions): Promise<void> {
    if (this.hasChanges) {
      return;
    }

    const adjustEdit = edits.find((e) => (e.action as string) === 'adjust');
    if (adjustEdit) {
      const params = adjustEdit.parameters as unknown as {
        brightness: number;
        contrast: number;
        saturation: number;
        hue: number;
        sharpness: number;
      };
      this.brightness = Math.round((params.brightness - 1) * 100);
      this.contrast = Math.round((params.contrast - 1) * 100);
      this.saturation = Math.round((params.saturation - 1) * 100);
      this.sharpness = Math.round(params.sharpness * 50);
      if (params.hue <= 30) {
        this.warmth = Math.round((params.hue / 30) * 100);
      } else if (params.hue >= 330) {
        this.warmth = Math.round(((params.hue - 360) / 30) * 100);
      } else {
        this.warmth = 0;
      }
    }

    if (edits.some((e) => (e.action as string) === 'auto-enhance')) {
      this.isAutoEnhance = true;
    }
  }

  onDeactivate() {
    // Preserve slider state when switching tools — the derived `edits` keeps feeding the editor.
  }

  // eslint-disable-next-line @typescript-eslint/require-await
  async resetAllChanges() {
    this.brightness = defaultValues.brightness;
    this.contrast = defaultValues.contrast;
    this.saturation = defaultValues.saturation;
    this.warmth = defaultValues.warmth;
    this.sharpness = defaultValues.sharpness;
    this.isAutoEnhance = false;
    this.activeFilter = 'original';
    this.hasChanges = false;
  }
}

export const adjustManager = new AdjustManager();
