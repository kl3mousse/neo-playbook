/**
 * In-memory, TTL-cached game catalog with prebuilt search indexes.
 *
 * Reads the entire `games` collection at most once per
 * `CACHE_TTL_MS`, builds normalized tokens / n-grams / aliases / sequel
 * numbers / cover image URLs once, and groups by normalized platform.
 *
 * This replaces the previous "load candidates per recognized item"
 * pattern that hit Firestore N times per scan job.
 */

import { Firestore } from "firebase-admin/firestore";
import { aliasesForTitle } from "./aliases";
import {
  extractSequelNumber,
  generateNgrams,
  normalizeText,
  tokenize,
} from "./text";
import { normalizePlatform, relatedPlatforms } from "./platforms";
import { GameCandidate } from "./types";

const CACHE_TTL_MS = 5 * 60 * 1000;
const GAMES_FETCH_LIMIT = 2000;

type CacheEntry = {
  loadedAt: number;
  byPlatform: Map<string, GameCandidate[]>;
  all: GameCandidate[];
};

let cache: CacheEntry | null = null;
let inflight: Promise<CacheEntry> | null = null;

function parseYear(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const n = parseInt(value, 10);
    if (Number.isFinite(n)) return n;
  }
  return null;
}

function pickCoverImageUrl(raw: Record<string, unknown>): string | null {
  const images = raw.images;
  if (!images || typeof images !== "object") return null;
  const candidates: Array<{ url: string; priority: number; isPrimary: boolean }> = [];
  for (const value of Object.values(images as Record<string, unknown>)) {
    if (!value || typeof value !== "object") continue;
    const img = value as Record<string, unknown>;
    const url = typeof img.url === "string" ? img.url : "";
    if (!url) continue;
    candidates.push({
      url,
      priority: typeof img.priority === "number" ? img.priority : 2,
      isPrimary: img.is_primary === true,
    });
  }
  if (candidates.length === 0) return null;
  candidates.sort((a, b) => {
    if (a.isPrimary !== b.isPrimary) return a.isPrimary ? -1 : 1;
    return a.priority - b.priority;
  });
  return candidates[0]?.url ?? null;
}

function buildCandidate(id: string, raw: Record<string, unknown>): GameCandidate {
  const title = typeof raw.title === "string" ? raw.title : "";
  const altTitle = typeof raw.alt_title === "string" && raw.alt_title.length > 0
    ? (raw.alt_title as string)
    : null;
  const platform = typeof raw.platform === "string" ? raw.platform : "";

  const aliases = new Set<string>();
  for (const a of aliasesForTitle(title)) aliases.add(a);
  if (altTitle) for (const a of aliasesForTitle(altTitle)) aliases.add(a);
  if (Array.isArray(raw.aliases)) {
    for (const a of raw.aliases as unknown[]) {
      if (typeof a === "string" && a.trim()) aliases.add(normalizeText(a));
    }
  }

  const normalizedTitle = normalizeText(title);
  const normalizedAltTitles = altTitle ? [normalizeText(altTitle)] : [];

  const tokens = new Set<string>();
  for (const t of tokenize(title)) tokens.add(t);
  if (altTitle) for (const t of tokenize(altTitle)) tokens.add(t);
  for (const a of aliases) for (const t of tokenize(a)) tokens.add(t);

  const ngrams = new Set<string>();
  for (const g of generateNgrams(title)) ngrams.add(g);
  if (altTitle) for (const g of generateNgrams(altTitle)) ngrams.add(g);
  for (const a of aliases) for (const g of generateNgrams(a)) ngrams.add(g);

  const titleSequel = extractSequelNumber(title);
  const altSequel = altTitle ? extractSequelNumber(altTitle) : null;

  return {
    id,
    title,
    altTitle,
    platform,
    platformNormalized: normalizePlatform(platform),
    publisher: typeof raw.publisher === "string" ? raw.publisher : null,
    year: parseYear(raw.year),
    aliases: Array.from(aliases),
    searchTokens: Array.from(tokens),
    ngrams,
    normalizedTitle,
    normalizedAltTitles,
    sequelNumber: titleSequel ?? altSequel,
    coverImageUrl: pickCoverImageUrl(raw),
  };
}

async function fetchCatalog(db: Firestore): Promise<CacheEntry> {
  const snap = await db.collection("games").limit(GAMES_FETCH_LIMIT).get();
  const all: GameCandidate[] = snap.docs.map((d) => buildCandidate(d.id, d.data()));
  const byPlatform = new Map<string, GameCandidate[]>();
  for (const c of all) {
    const key = c.platformNormalized || "_";
    const list = byPlatform.get(key);
    if (list) {
      list.push(c);
    } else {
      byPlatform.set(key, [c]);
    }
  }
  return { loadedAt: Date.now(), byPlatform, all };
}

export async function getCatalog(db: Firestore): Promise<CacheEntry> {
  const now = Date.now();
  if (cache && now - cache.loadedAt < CACHE_TTL_MS) return cache;
  if (inflight) return inflight;
  inflight = (async () => {
    try {
      const entry = await fetchCatalog(db);
      cache = entry;
      return entry;
    } finally {
      inflight = null;
    }
  })();
  return inflight;
}

/**
 * Return the candidate pool for a normalized platform, expanded to
 * its related-platform group. If the requested platform is unknown
 * or yields nothing, fall back to the full catalog so we still get
 * a chance at finding a match.
 */
export function candidatesForPlatform(
  entry: CacheEntry,
  normalizedPlatform: string,
): GameCandidate[] {
  if (!normalizedPlatform) return entry.all;
  const out: GameCandidate[] = [];
  for (const p of relatedPlatforms(normalizedPlatform)) {
    const list = entry.byPlatform.get(p);
    if (list) out.push(...list);
  }
  return out.length > 0 ? out : entry.all;
}

/** Test/dev hook to drop the in-memory cache. */
export function _resetCatalogCache(): void {
  cache = null;
  inflight = null;
}
