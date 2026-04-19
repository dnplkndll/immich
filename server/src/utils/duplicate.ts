import { AssetResponseDto } from 'src/dtos/asset-response.dto';

/**
 * Color gamut scores based on ICC profile description.
 * Wider gamuts score higher as they preserve more color information.
 */
const COLOR_GAMUT_SCORES: [string, number][] = [
  ['prophoto rgb', 15],
  ['rec. 2020', 15],
  ['rec.2020', 15],
  ['bt.2020', 15],
  ['adobe rgb', 10],
  ['display p3', 8],
];

/**
 * Scores bit depth on a non-linear scale: 8→0, 10→10, 12→18, 14→22, 16→25.
 * Null defaults to 8-bit (consumer default).
 */
function scoreBitDepth(bitsPerSample: number | null | undefined): number {
  if (bitsPerSample == null || bitsPerSample <= 8) {
    return 0;
  }
  if (bitsPerSample >= 16) {
    return 25;
  }
  // Linear interpolation from 8→0 to 16→25
  return Math.round(((bitsPerSample - 8) / 8) * 25);
}

/**
 * Scores color gamut by matching profileDescription against known gamut names.
 * Falls back to colorspace field. Null/unknown defaults to sRGB (score 0).
 */
function scoreColorGamut(profileDescription: string | null | undefined, colorspace: string | null | undefined): number {
  for (const field of [profileDescription, colorspace]) {
    if (!field) {
      continue;
    }
    const lower = field.toLowerCase();
    // Skip conversion profiles like "ProPhoto RGB to sRGB"
    if (lower.includes(' to ')) {
      continue;
    }
    for (const [key, score] of COLOR_GAMUT_SCORES) {
      if (lower.includes(key)) {
        return score;
      }
    }
  }
  return 0;
}

interface GroupContext {
  maxFileSize: number;
  maxExifCount: number;
  maxBitsPerPixelPerByte: number;
}

interface ScoringCandidate {
  asset: AssetResponseDto;
  pixels: number;
  bitsPerSample: number;
  fileSize: number;
  exifCount: number;
  bitsPerPixelPerByte: number;
}

/**
 * Counts all truthy values in the exifInfo object.
 * This matches the client implementation in web/src/lib/utils/exif-utils.ts
 *
 * @param asset Asset with optional exifInfo
 * @returns Count of truthy EXIF values
 */
export const getExifCount = (asset: AssetResponseDto): number => {
  return Object.values(asset.exifInfo ?? {}).filter(Boolean).length;
};

function buildCandidate(asset: AssetResponseDto): ScoringCandidate {
  const exif = asset.exifInfo;
  const width = exif?.exifImageWidth ?? asset.width ?? 0;
  const height = exif?.exifImageHeight ?? asset.height ?? 0;
  const pixels = width * height;
  const bitsPerSample = exif?.bitsPerSample ?? 8;
  const fileSize = exif?.fileSizeInByte ?? 0;
  const exifCount = getExifCount(asset);
  // Higher = more raw image data per stored byte = more efficient codec (e.g. HEIC > JPEG).
  const bitsPerPixelPerByte = fileSize > 0 ? (pixels * bitsPerSample) / fileSize : 0;

  return { asset, pixels, bitsPerSample, fileSize, exifCount, bitsPerPixelPerByte };
}

function buildGroupContext(candidates: ScoringCandidate[]): GroupContext {
  return {
    maxFileSize: Math.max(...candidates.map((c) => c.fileSize), 1),
    maxExifCount: Math.max(...candidates.map((c) => c.exifCount), 1),
    maxBitsPerPixelPerByte: Math.max(...candidates.map((c) => c.bitsPerPixelPerByte), 1),
  };
}

/**
 * Computes a multi-factor quality score for a duplicate candidate.
 *
 * Photos: compression efficiency rewards more efficient codecs (HEIC > JPEG at same size).
 * Videos: compression efficiency skipped — a re-encoded 720p copy misleadingly scores
 *         higher than the 1080p original because file size shrinks faster than pixels.
 *         Resolution and file size are weighted higher for videos instead.
 */
function computeQualityScore(candidate: ScoringCandidate, ctx: GroupContext): number {
  const isVideo = candidate.asset.type === 'VIDEO';
  const megapixels = candidate.pixels / 1_000_000;
  const pixelScore = isVideo ? Math.min(megapixels * 20, 40) : Math.min(megapixels, 30);

  const bitDepthScore = scoreBitDepth(candidate.bitsPerSample);

  const exif = candidate.asset.exifInfo;
  const gamutScore = scoreColorGamut(exif?.profileDescription, exif?.colorspace);

  const livePhotoScore = candidate.asset.livePhotoVideoId ? 10 : 0;

  const compressionScore = isVideo ? 0 : (candidate.bitsPerPixelPerByte / ctx.maxBitsPerPixelPerByte) * 10;

  const fileSizeScore = (candidate.fileSize / ctx.maxFileSize) * (isVideo ? 15 : 5);

  const metadataScore = (candidate.exifCount / ctx.maxExifCount) * 5;

  return pixelScore + bitDepthScore + gamutScore + livePhotoScore + compressionScore + fileSizeScore + metadataScore;
}

/**
 * Suggests the best duplicate asset to keep from a list of duplicates.
 *
 * Uses a multi-factor quality score based on objective, measurable properties:
 * pixel count, bit depth, color gamut, live photo presence, file size,
 * metadata richness, and (for photos) compression efficiency.
 *
 * @param assets List of duplicate assets
 * @returns The best asset to keep, or undefined if empty list
 */
export const suggestDuplicate = (assets: AssetResponseDto[]): AssetResponseDto | undefined => {
  if (assets.length === 0) {
    return undefined;
  }

  const candidates = assets.map((asset) => buildCandidate(asset));
  const ctx = buildGroupContext(candidates);

  let bestCandidate = candidates[0];
  let bestScore = computeQualityScore(bestCandidate, ctx);

  for (let i = 1; i < candidates.length; i++) {
    const score = computeQualityScore(candidates[i], ctx);
    if (score > bestScore) {
      bestScore = score;
      bestCandidate = candidates[i];
    }
  }

  return bestCandidate.asset;
};

/**
 * Suggests the best duplicate asset IDs to keep from a list of duplicates.
 * Returns an array with a single asset ID (the best candidate), or empty if no assets.
 */
export const suggestDuplicateKeepAssetIds = (assets: AssetResponseDto[]): string[] => {
  const suggested = suggestDuplicate(assets);
  return suggested ? [suggested.id] : [];
};
