<script lang="ts">
  import { adjustManager, type AdjustValues } from '$lib/managers/edit/adjust-manager.svelte';
  import { Button, IconButton } from '@immich/ui';
  import { mdiImageFilterFrames, mdiTune } from '@mdi/js';
  import { t } from 'svelte-i18n';
  import AdjustSlider from './adjust-slider.svelte';
  import FilterPresets from './filter-presets.svelte';

  type Tab = 'adjustments' | 'filters';

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

  let activeTab: Tab = $state('adjustments');
</script>

<div class="mt-3 px-4">
  <div class="flex h-10 w-full items-center justify-between text-sm mt-2">
    <div class="flex items-center gap-1">
      <IconButton
        shape="round"
        size="small"
        variant={activeTab === 'adjustments' ? 'filled' : 'ghost'}
        color={activeTab === 'adjustments' ? 'primary' : 'secondary'}
        icon={mdiTune}
        aria-label={$t('adjust')}
        onclick={() => (activeTab = 'adjustments')}
      />
      <IconButton
        shape="round"
        size="small"
        variant={activeTab === 'filters' ? 'filled' : 'ghost'}
        color={activeTab === 'filters' ? 'primary' : 'secondary'}
        icon={mdiImageFilterFrames}
        aria-label={$t('filters')}
        onclick={() => (activeTab = 'filters')}
      />
    </div>
    {#if activeTab === 'adjustments'}
      <Button
        size="small"
        shape="round"
        variant={adjustManager.isAutoEnhance ? 'filled' : 'outline'}
        onclick={() => adjustManager.setAutoEnhance()}
      >
        {$t('auto_enhance')}
      </Button>
    {/if}
  </div>

  {#if activeTab === 'adjustments'}
    <div class="flex flex-col gap-3 mt-4">
      {#each sliders as slider (slider.key)}
        <AdjustSlider
          label={slider.label}
          value={adjustManager[slider.key]}
          onChange={(v) => adjustManager.setValue(slider.key, v)}
        />
      {/each}
    </div>
  {:else}
    <div class="mt-4">
      <FilterPresets />
    </div>
  {/if}
</div>
