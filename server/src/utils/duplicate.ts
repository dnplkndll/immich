import { AssetResponseDto } from 'src/dtos/asset-response.dto';
import { AssetType } from 'src/enum';

/**
 * Maximum contribution of each quality factor to the total score. Kept in one
 * place so the relative weighting of the heuristics is auditable at a glance.
 * Non-video/non-image asset types (AUDIO/OTHER) fall through the photo path.
 */
const WEIGHTS = {
  /** Resolution (megapixels), capped. Videos weigh resolution higher than photos. */
  pixelsPhoto: 30,
  pixelsVideo: 40,
  /** Bit depth (see BIT_DEPTH_SCORE_CURVE). */
  bitDepth: 25,
  /** Widest ICC color gamut (see COLOR_GAMUT_SCORES). */
  gamut: 15,
  /** Asset carries a paired live-photo/motion video. */
  livePhoto: 10,
  /** Codec efficiency (raw data per stored byte); photos only. */
  compressionPhoto: 10,
  /** File size relative to the group max. Videos weigh size higher than photos. */
  fileSizePhoto: 5,
  fileSizeVideo: 15,
  /** EXIF richness relative to the group max. */
  metadata: 5,
} as const;

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
 * Bit-depth score breakpoints. Deliberately non-linear: the 8→10-bit jump is
 * perceptually the largest, with diminishing returns above, so higher-depth
 * originals are rewarded early. Values interpolate piecewise between breakpoints.
 */
const BIT_DEPTH_SCORE_CURVE: [number, number][] = [
  [8, 0],
  [10, 10],
  [12, 18],
  [14, 22],
  [16, 25],
];

/**
 * Scores bit depth on the non-linear curve 8→0, 10→10, 12→18, 14→22, 16→25,
 * interpolating piecewise for intermediate depths. Null defaults to 8-bit.
 */
function scoreBitDepth(bitsPerSample: number | null | undefined): number {
  const bits = bitsPerSample ?? 8;
  if (bits <= 8) {
    return 0;
  }
  if (bits >= 16) {
    return WEIGHTS.bitDepth;
  }
  for (let i = 1; i < BIT_DEPTH_SCORE_CURVE.length; i++) {
    const [x0, y0] = BIT_DEPTH_SCORE_CURVE[i - 1];
    const [x1, y1] = BIT_DEPTH_SCORE_CURVE[i];
    if (bits <= x1) {
      return Math.round(y0 + ((bits - x0) / (x1 - x0)) * (y1 - y0));
    }
  }
  return WEIGHTS.bitDepth;
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
  // Duplicate groups are small (a handful of assets), so spreading into Math.max is fine.
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
  const isVideo = candidate.asset.type === AssetType.Video;
  const megapixels = candidate.pixels / 1_000_000;
  // Video reaches full pixel points at 2 MP (20 pts/MP); photos scale at 1 pt/MP.
  const pixelScore = isVideo
    ? Math.min(megapixels * 20, WEIGHTS.pixelsVideo)
    : Math.min(megapixels, WEIGHTS.pixelsPhoto);

  const bitDepthScore = scoreBitDepth(candidate.bitsPerSample);

  const exif = candidate.asset.exifInfo;
  const gamutScore = scoreColorGamut(exif?.profileDescription, exif?.colorspace);

  const livePhotoScore = candidate.asset.livePhotoVideoId ? WEIGHTS.livePhoto : 0;

  // Codec efficiency (raw data per stored byte) rewards more efficient codecs across a
  // group (e.g. HEIC > JPEG). Skipped for video, where a re-encoded low-res copy would
  // score misleadingly high. NOTE: within a single codec this can prefer the smaller
  // (more-compressed) file; fileSize/resolution weighting is meant to offset that.
  const compressionScore = isVideo
    ? 0
    : (candidate.bitsPerPixelPerByte / ctx.maxBitsPerPixelPerByte) * WEIGHTS.compressionPhoto;

  const fileSizeScore =
    (candidate.fileSize / ctx.maxFileSize) * (isVideo ? WEIGHTS.fileSizeVideo : WEIGHTS.fileSizePhoto);

  const metadataScore = (candidate.exifCount / ctx.maxExifCount) * WEIGHTS.metadata;

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
