/**
 * Text normalization, tokenization, n-grams, fuzzy similarity,
 * sequel-number extraction, and variant detection.
 *
 * All functions are pure and dependency-free so they can be unit-tested
 * in isolation.
 */

export function normalizeText(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

export function tokenize(value: string): string[] {
  return normalizeText(value).split(" ").filter((t) => t.length > 0);
}

/** Character trigrams over the normalized text (with leading/trailing pad). */
export function generateNgrams(value: string, n = 3): Set<string> {
  const normalized = normalizeText(value);
  const result = new Set<string>();
  if (!normalized) return result;
  const padded = ` ${normalized} `;
  for (let i = 0; i <= padded.length - n; i++) {
    const gram = padded.slice(i, i + n);
    if (gram.trim().length > 0) {
      result.add(gram);
    }
  }
  return result;
}

export function jaccard(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 || b.size === 0) return 0;
  let inter = 0;
  for (const x of a) {
    if (b.has(x)) inter += 1;
  }
  const union = a.size + b.size - inter;
  return union === 0 ? 0 : inter / union;
}

export function levenshtein(a: string, b: string): number {
  if (a === b) return 0;
  if (a.length === 0) return b.length;
  if (b.length === 0) return a.length;
  const prev: number[] = new Array(b.length + 1);
  const curr: number[] = new Array(b.length + 1);
  for (let j = 0; j <= b.length; j++) prev[j] = j;
  for (let i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      curr[j] = Math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost);
    }
    for (let j = 0; j <= b.length; j++) prev[j] = curr[j];
  }
  return prev[b.length];
}

export function levenshteinSimilarity(a: string, b: string): number {
  if (!a && !b) return 1;
  const max = Math.max(a.length, b.length);
  if (max === 0) return 0;
  return 1 - levenshtein(a, b) / max;
}

const ROMAN_NUMERALS: Record<string, number> = {
  i: 1, ii: 2, iii: 3, iv: 4, v: 5,
  vi: 6, vii: 7, viii: 8, ix: 9, x: 10,
  xi: 11, xii: 12, xiii: 13,
};

/**
 * Extract a sequel marker number (or null) from a title.
 *
 * Handles arabic numerals ("Metal Slug 3"), roman numerals
 * ("Street Fighter II"), and 2/4-digit year tags ("KOF 98",
 * "King of Fighters 2002").
 *
 * Walks tokens from the END so that "Neo Geo Battle Coliseum"
 * does not get misread but "Metal Slug 3" does.
 */
export function extractSequelNumber(value: string): number | null {
  const normalized = normalizeText(value);
  if (!normalized) return null;
  const tokens = normalized.split(" ");
  for (let i = tokens.length - 1; i >= 0; i--) {
    const t = tokens[i];
    if (/^\d{1,4}$/.test(t)) {
      const n = parseInt(t, 10);
      if (n >= 60 && n <= 99) return n; // 2-digit year tag (KOF 98)
      if (n >= 1980 && n <= 2099) return n; // 4-digit year tag (KOF 2002)
      if (n >= 1 && n <= 20) return n; // straight sequel number
    }
    const roman = ROMAN_NUMERALS[t];
    if (roman != null) return roman;
  }
  return null;
}

/**
 * Common variant/edition tokens that distinguish releases sharing a base name.
 * "Street Fighter II Turbo" vs "Street Fighter II", "KOF '98 Ultimate Match",
 * "Vampire Hunter", "Real Bout Fatal Fury Special", etc.
 */
export const VARIANT_TOKENS = new Set<string>([
  "turbo",
  "super",
  "hyper",
  "ex",
  "extra",
  "second",
  "third",
  "match",
  "tournament",
  "championship",
  "ultimate",
  "ultra",
  "plus",
  "alpha",
  "zero",
  "special",
  "savior",
  "hunter",
  "real",
  "bout",
  "dream",
  "neowave",
  "rage",
  "anniversary",
  "remix",
]);

export function extractVariantTokens(value: string): Set<string> {
  const out = new Set<string>();
  for (const t of tokenize(value)) {
    if (VARIANT_TOKENS.has(t)) out.add(t);
  }
  return out;
}
