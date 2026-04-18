<script lang="ts">
  interface Props {
    label: string;
    value: number;
    min?: number;
    max?: number;
    step?: number;
    onChange: (value: number) => void;
  }

  let { label, value, min = -100, max = 100, step = 1, onChange }: Props = $props();

  const clamp = (n: number) => Math.min(max, Math.max(min, Math.round(n)));

  const handleNumberInput = (raw: string) => {
    if (raw === '' || raw === '-') {
      return;
    }
    const n = Number(raw);
    if (Number.isNaN(n)) {
      return;
    }
    onChange(clamp(n));
  };
</script>

<div class="flex flex-col gap-1">
  <div class="flex items-center justify-between text-xs text-immich-fg dark:text-immich-dark-fg">
    <label class="cursor-pointer" for="adjust-slider-{label}">{label}</label>
    <input
      id="adjust-slider-{label}-num"
      type="number"
      {min}
      {max}
      {step}
      {value}
      aria-label="{label} value"
      class="tabular-nums w-12 text-right bg-transparent border border-gray-300 dark:border-gray-600 rounded px-1 py-0.5 focus:outline-none focus:border-immich-primary dark:focus:border-immich-dark-primary"
      oninput={(e) => handleNumberInput(e.currentTarget.value)}
    />
  </div>
  <input
    id="adjust-slider-{label}"
    type="range"
    {min}
    {max}
    {step}
    aria-label={label}
    {value}
    oninput={(e) => onChange(Number(e.currentTarget.value))}
    class="w-full h-1.5 rounded-lg appearance-none cursor-pointer accent-immich-primary dark:accent-immich-dark-primary bg-gray-300 dark:bg-gray-600"
  />
</div>
