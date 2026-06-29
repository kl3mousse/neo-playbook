/**
 * Cross-language and abbreviation aliases for arcade titles.
 *
 * We attach these to each catalog entry at index time so the
 * retriever can match e.g. "KOF 98" against "The King of Fighters '98",
 * or "Garou Densetsu Special" against "Fatal Fury Special".
 *
 * The map key is a fragment that, if present in a normalized
 * catalog title, attaches all listed aliases to that entry.
 * Matching is substring-based on the *normalized* (lowercased,
 * punctuation-stripped) title.
 */

import { normalizeText } from "./text";

const RAW_TITLE_ALIASES: Record<string, string[]> = {
  // King of Fighters family
  "the king of fighters": ["kof", "king of fighters"],
  "king of fighters": ["kof"],
  // Samurai Shodown <-> Samurai Spirits
  "samurai shodown": ["samurai spirits", "samsho"],
  // Fatal Fury <-> Garou Densetsu
  "fatal fury": ["garou densetsu", "garou", "ff"],
  "real bout fatal fury": ["real bout garou densetsu", "real bout"],
  "garou mark of the wolves": ["garou", "mark of the wolves", "motw"],
  // Art of Fighting <-> Ryuko no Ken
  "art of fighting": ["ryuko no ken", "aof"],
  // The Last Blade <-> Bakumatsu Roman
  "the last blade": ["bakumatsu roman", "last blade"],
  // Metal Slug
  "metal slug": ["ms"],
  // Street Fighter II
  "street fighter ii": ["sf2", "street fighter 2", "sfii"],
  "street fighter ii turbo": ["sf2 turbo", "street fighter 2 turbo"],
  "super street fighter ii": ["ssf2", "super sf2"],
  "super street fighter ii turbo": ["ssf2t", "super street fighter 2 turbo"],
  // Street Fighter Alpha / Zero
  "street fighter alpha": ["street fighter zero", "sfa", "sfz"],
  "street fighter alpha 2": ["street fighter zero 2", "sfa2", "sfz2"],
  "street fighter alpha 3": ["street fighter zero 3", "sfa3", "sfz3"],
  // Street Fighter III
  "street fighter iii": ["sf3", "street fighter 3", "sfiii"],
  "street fighter iii 2nd impact": ["sf3 2nd impact"],
  "street fighter iii 3rd strike": ["sf3 3rd strike", "3s"],
  // Vampire <-> Darkstalkers
  "darkstalkers": ["vampire"],
  "darkstalkers the night warriors": ["vampire", "vampire the night warriors"],
  "night warriors darkstalkers revenge": ["vampire hunter"],
  "darkstalkers 3": ["vampire savior"],
  // Capcom vs SNK / Marvel vs Capcom
  "capcom vs snk": ["cvs"],
  "capcom vs snk 2": ["cvs2"],
  "marvel vs capcom": ["mvc"],
  "marvel vs capcom 2": ["mvc2"],
  "x men vs street fighter": ["xmen vs sf", "x men vs sf"],
  // Pulstar etc
  "pulstar": ["pulstar"],
};

const COMPILED_ALIASES: Array<[string, string[]]> = Object.entries(
  RAW_TITLE_ALIASES,
).map(([k, v]) => [normalizeText(k), v.map((x) => normalizeText(x))]);

/** Return alias strings to attach to a catalog entry given its title. */
export function aliasesForTitle(title: string): string[] {
  const normalized = normalizeText(title);
  if (!normalized) return [];
  const out = new Set<string>();
  for (const [needle, values] of COMPILED_ALIASES) {
    if (normalized.includes(needle)) {
      for (const v of values) out.add(v);
    }
  }
  return Array.from(out);
}
