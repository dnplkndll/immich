import { computeBer, popcount32, toSigned32 } from 'src/services/audio-fingerprint.service';
import { describe, expect, it } from 'vitest';

describe('audio fingerprint BER helpers', () => {
  describe('popcount32', () => {
    it('counts set bits in a 32-bit word', () => {
      expect(popcount32(0)).toBe(0);
      expect(popcount32(0b1011)).toBe(3);
      expect(popcount32(0xffffffff)).toBe(32);
    });
  });

  describe('toSigned32', () => {
    it('reinterprets an unsigned 32-bit int as signed (round-trips Chromaprint values)', () => {
      expect(toSigned32(0)).toBe(0);
      expect(toSigned32(0xffffffff)).toBe(-1);
      expect(toSigned32(0x80000000)).toBe(-2_147_483_648);
      // XOR of a value with itself is 0 regardless of sign reinterpretation.
      const v = toSigned32(0xdeadbeef);
      expect(v ^ v).toBe(0);
    });
  });

  describe('computeBer', () => {
    it('returns 0 for identical fingerprints', () => {
      expect(computeBer([1, 2, 3], [1, 2, 3])).toBe(0);
    });

    it('returns 1 (no match) when either fingerprint is empty', () => {
      expect(computeBer([], [])).toBe(1);
      expect(computeBer([1, 2], [])).toBe(1);
    });

    it('returns 1 when lengths differ by more than the mismatch ratio (20%)', () => {
      expect(computeBer([1, 2, 3, 4, 5], [1])).toBe(1);
    });

    it('does not reject a length difference of exactly 20%', () => {
      // 5 vs 4 words => (5-4)/5 = 0.2, which is not > 0.2, so it is compared.
      expect(computeBer([0, 0, 0, 0, 0], [0, 0, 0, 0])).toBe(0);
    });

    it('returns 1 when every bit differs', () => {
      expect(computeBer([0], [toSigned32(0xffffffff)])).toBe(1);
    });

    it('returns the fraction of differing bits over the compared words', () => {
      expect(computeBer([0], [1])).toBeCloseTo(1 / 32, 10);
      expect(computeBer([0, 0], [1, 1])).toBeCloseTo(2 / 64, 10);
    });
  });
});
