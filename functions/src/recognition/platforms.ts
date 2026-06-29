/**
 * Platform normalization for arcade / console naming variants.
 *
 * Real-world inputs we have to handle:
 *  - MVS / Neo Geo MVS / NeoGeo MVS / Neo-Geo MVS
 *  - AES / Neo Geo AES / Home cart
 *  - NGCD / Neo Geo CD / Neo-Geo CD
 *  - CPS1 / CPS 1 / Capcom Play System / Capcom Play System 1
 *  - CPS2 / CPS 2 / Capcom Play System 2
 *  - CPS3 / Capcom Play System 3
 *  - PGM / Polygame Master
 */

import { normalizeText } from "./text";

const PLATFORM_ALIASES: Record<string, string[]> = {
  mvs: [
    "mvs", "neo geo mvs", "neogeo mvs", "neo-geo mvs",
    "neo geo arcade", "snk arcade", "snk mvs",
  ],
  aes: [
    "aes", "neo geo aes", "neogeo aes", "neo-geo aes",
    "home cart", "neo geo home", "snk aes",
  ],
  ngcd: [
    "ngcd", "neo geo cd", "neogeo cd", "neo-geo cd",
    "neo geo cdz",
  ],
  cps1: [
    "cps1", "cps 1", "capcom cps1", "capcom cps 1",
    "capcom play system", "capcom play system 1",
  ],
  cps2: [
    "cps2", "cps 2", "capcom cps2", "capcom cps 2",
    "capcom play system 2",
  ],
  cps3: [
    "cps3", "cps 3", "capcom cps3", "capcom play system 3",
  ],
  pgm: [
    "pgm", "polygame master", "igs pgm",
  ],
};

/** Platforms that often share the same titles (treat as related, not mismatched). */
const PLATFORM_GROUPS: Record<string, string[]> = {
  mvs: ["mvs", "aes"],
  aes: ["mvs", "aes"],
};

const ALIAS_LOOKUP = (() => {
  const map = new Map<string, string>();
  for (const [canonical, values] of Object.entries(PLATFORM_ALIASES)) {
    for (const v of values) {
      const key = normalizeText(v).replace(/\s+/g, "");
      map.set(key, canonical);
    }
  }
  return map;
})();

export function normalizePlatform(platform: string | undefined | null): string {
  const raw = normalizeText(platform ?? "");
  if (!raw) return "";
  const compact = raw.replace(/\s+/g, "");
  const hit = ALIAS_LOOKUP.get(compact);
  if (hit) return hit;
  // Fall back to the compact normalized string as-is so unknown
  // platforms still group consistently.
  return compact;
}

export function relatedPlatforms(canonical: string): string[] {
  return PLATFORM_GROUPS[canonical] ?? [canonical];
}

export type PlatformAffinity = "match" | "related" | "mismatch" | "unknown";

export function platformAffinity(
  recognized: string,
  catalog: string,
): PlatformAffinity {
  if (!recognized || !catalog) return "unknown";
  if (recognized === catalog) return "match";
  if (relatedPlatforms(recognized).includes(catalog)) return "related";
  return "mismatch";
}
