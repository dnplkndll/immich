<script lang="ts">
  import { adjustManager, type AdjustValues } from '$lib/managers/edit/adjust-manager.svelte';
  import { Button } from '@immich/ui';
  import { t } from 'svelte-i18n';
  import FilterPresets from './filter-presets.svelte';

  interface SliderConfig {
    key: keyof AdjustValues;
    label: string;
  }

  const sliders: SliderConfig[] = [
    { key: 'brightness', label: $t('brightness') },
    { key: 'contrast', label: $t('contrast') },
    { key: 'saturation', label: $t('saturation') },
    { key: 'warmth', label: $t('warmth') },
    { key: 'sharpness', label: $t('sharpness') },
  ];
</script>

<div class="mt-3 px-4">
  <div class="flex h-10 w-full items-center justify-between text-sm mt-2">
    <h2>{$t('adjust')}</h2>
    <Button
      size="small"
      shape="round"
      variant={adjustManager.isAutoEnhance ? 'filled' : 'outline'}
      onclick={() => adjustManager.setAutoEnhance()}
    >
      {$t('auto_enhance')}
    </Button>
  </div>

  <div class="flex flex-col gap-3 mt-2">
    {#each sliders as slider (slider.key)}
      <div class="flex flex-col gap-1">
        <div class="flex items-center justify-between text-xs text-immich-fg dark:text-immich-dark-fg">
          <span>{slider.label}</span>
          <span class="tabular-nums w-8 text-right">{adjustManager[slider.key]}</span>
        </div>
        <input
          type="range"
          min="-100"
          max="100"
          step="1"
          aria-label={slider.label}
          value={adjustManager[slider.key]}
          oninput={(e) => adjustManager.setValue(slider.key, Number(e.currentTarget.value))}
          class="w-full h-1.5 rounded-lg appearance-none cursor-pointer accent-immich-primary dark:accent-immich-dark-primary bg-gray-300 dark:bg-gray-600"
        />
      </div>
    {/each}
  </div>

  <div class="flex h-10 w-full items-center justify-between text-sm mt-6">
    <h2>{$t('filters')}</h2>
  </div>

  <FilterPresets />
</div>
