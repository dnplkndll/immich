<script lang="ts">
  import { adjustManager, cssFilterForAdjustValues, filterPresets } from '$lib/managers/edit/adjust-manager.svelte';
  import { editManager } from '$lib/managers/edit/edit-manager.svelte';
  import { getAssetMediaUrl } from '$lib/utils';
  import { AssetMediaSize } from '@immich/sdk';
  import { t } from 'svelte-i18n';

  const thumbnailUrl = $derived(
    editManager.currentAsset
      ? getAssetMediaUrl({
          id: editManager.currentAsset.id,
          size: AssetMediaSize.Thumbnail,
          cacheKey: editManager.currentAsset.thumbhash,
        })
      : null,
  );
</script>

<div class="grid grid-cols-4 gap-2 pb-2">
  {#each filterPresets as preset (preset.name)}
    {@const isActive = adjustManager.activeFilter === preset.name}
    {@const label = $t(preset.labelKey)}
    <button
      type="button"
      class="flex flex-col items-center gap-1 cursor-pointer focus:outline-none"
      onclick={() => adjustManager.applyPreset(preset)}
    >
      <div
        class="w-full aspect-square rounded-lg overflow-hidden bg-gray-200 dark:bg-gray-700 transition-all {isActive
          ? 'ring-2 ring-immich-primary dark:ring-immich-dark-primary ring-offset-2 ring-offset-immich-bg dark:ring-offset-immich-dark-bg'
          : 'ring-1 ring-gray-300 dark:ring-gray-600'}"
      >
        {#if thumbnailUrl}
          <img
            src={thumbnailUrl}
            alt={label}
            class="w-full h-full object-cover"
            style:filter={cssFilterForAdjustValues(preset.values)}
            draggable="false"
          />
        {:else}
          <div class="w-full h-full flex items-center justify-center text-xs">{label.slice(0, 3)}</div>
        {/if}
      </div>
      <span
        class="text-xs truncate w-full text-center {isActive
          ? 'text-immich-primary dark:text-immich-dark-primary font-medium'
          : 'text-immich-fg/70 dark:text-immich-dark-fg/70'}"
      >
        {label}
      </span>
    </button>
  {/each}
</div>
