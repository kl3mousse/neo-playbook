/**
 * Retrieval + initial ranking of catalog candidates for a single
 * extracted item.
 *
 * Scoring components per candidate:
 *  - title_score:    best of exact / substring / token-jaccard /
 *                    trigram-jaccard / Levenshtein similarity,
 *                    over title + alt_title + aliases
 *  - sequel_score:   sequel-number consistency bonus/penalty
 *  - variant_score:  edition/variant token consistency
 *  - platform_score: match (+), related (+small), mismatch (-), unknown (0)
 *
 * Importantly: a candidate that lacks a sequel number when the
 * recognized text has one gets penalized, so "Metal Slug" does NOT
 * rank near "Metal Slug 3" for an image showing "METAL SLUG 3".
 */

import {
  CandidateForModel,
  ExtractedItem,
  GameCandidate,
  RankedCandidate,
} from "./types";
import {
  extractSequelNumber,
  extractVariantTokens,
  generateNgrams,
  jaccard,
  levenshteinSimilarity,
  normalizeText,
  tokenize,
} from "./text";
import { platformAffinity } from "./platforms";

const TOP_K = 25;

type QueryTerm = {
  text: string;
  sequel: number | null;
  variants: Set<string>;
  tokens: Set<string>;
  ngrams: Set<string>;
};

function buildQueryTerm(text: string): QueryTerm | null {
  const normalized = normalizeText(text);
  if (!normalized || normalized.length < 2) return null;
  return {
    text: normalized,
    sequel: extractSequelNumber(normalized),
    variants: extractVariantTokens(normalized),
    tokens: new Set(tokenize(normalized)),
    ngrams: generateNgrams(normalized),
  };
}

function buildQueryTerms(item: ExtractedItem): QueryTerm[] {
  const seen = new Set<string>();
  const out: QueryTerm[] = [];
  const sources: string[] = [];
  if (item.raw_title_hint) sources.push(item.raw_title_hint);
  if (item.visible_text) sources.push(item.visible_text);
  for (const line of item.visible_text_lines ?? []) {
    if (line && line.trim().length >= 3) sources.push(line);
  }
  for (const s of sources) {
    const term = buildQueryTerm(s);
    if (!term) continue;
    if (seen.has(term.text)) continue;
    seen.add(term.text);
    out.push(term);
  }
  return out;
}

function scoreOneTitle(termText: string, termTokens: Set<string>, termNgrams: Set<string>, candidateText: string): number {
  if (!candidateText) return 0;
  if (termText === candidateText) return 1.0;
  if (termText.length >= 4 && (termText.includes(candidateText) || candidateText.includes(termText))) {
    return 0.88;
  }
  const tokenJ = jaccard(termTokens, new Set(tokenize(candidateText)));
  const ngramJ = jaccard(termNgrams, generateNgrams(candidateText));
  const lev = levenshteinSimilarity(termText, candidateText);
  // Combine: ngram + lev are strongest when one side is short or
  // strangely tokenized (e.g. "kof98"); token jaccard is strongest
  // when both are clean multi-word titles.
  return Math.max(
    tokenJ * 0.6 + ngramJ * 0.3 + lev * 0.1,
    ngramJ * 0.55 + lev * 0.45,
  );
}

function scoreTitleAgainstCandidate(term: QueryTerm, candidate: GameCandidate): number {
  const surfaces: string[] = [];
  if (candidate.normalizedTitle) surfaces.push(candidate.normalizedTitle);
  for (const a of candidate.normalizedAltTitles) if (a) surfaces.push(a);
  for (const a of candidate.aliases) if (a) surfaces.push(a);
  let best = 0;
  for (const s of surfaces) {
    const score = scoreOneTitle(term.text, term.tokens, term.ngrams, s);
    if (score > best) best = score;
    if (best >= 1) break;
  }
  return best;
}

function sequelScore(term: QueryTerm, candidate: GameCandidate): number {
  const ts = term.sequel;
  const cs = candidate.sequelNumber;
  if (ts == null && cs == null) return 0;
  if (ts != null && cs != null && ts === cs) return 0.10;
  if (ts != null && cs == null) return -0.18; // recognized has a number, catalog title doesn't
  if (ts == null && cs != null) return -0.06; // mild preference for base game
  return -0.22; // different sequel numbers
}

function variantScore(term: QueryTerm, candidate: GameCandidate): number {
  if (term.variants.size === 0) return 0;
  const candVariants = extractVariantTokens(candidate.title);
  if (candVariants.size === 0) return -0.10;
  let inter = 0;
  for (const v of term.variants) if (candVariants.has(v)) inter += 1;
  return inter === term.variants.size ? 0.05 : -0.08;
}

function platformScore(recognized: string, candidate: GameCandidate): number {
  switch (platformAffinity(recognized, candidate.platformNormalized)) {
    case "match": return 0.10;
    case "related": return 0.05;
    case "mismatch": return -0.20;
    case "unknown": return 0;
  }
}

export type RetrievalOptions = {
  /** Normalized platform string (use the empty string if unknown). */
  recognizedPlatform: string;
  topK?: number;
};

export function rankCandidates(
  catalog: GameCandidate[],
  item: ExtractedItem,
  options: RetrievalOptions,
): RankedCandidate[] {
  const terms = buildQueryTerms(item);
  if (terms.length === 0 || catalog.length === 0) return [];

  const recognizedPlatform = options.recognizedPlatform || "";
  const topK = options.topK ?? TOP_K;

  const ranked: RankedCandidate[] = catalog.map((game) => {
    let bestTitle = 0;
    let bestSequel = 0;
    let bestVariant = 0;
    let bestTerm: QueryTerm | null = null;
    for (const term of terms) {
      const title = scoreTitleAgainstCandidate(term, game);
      if (title > bestTitle) {
        bestTitle = title;
        bestTerm = term;
      }
    }
    if (bestTerm) {
      bestSequel = sequelScore(bestTerm, game);
      bestVariant = variantScore(bestTerm, game);
    }
    const platform = platformScore(recognizedPlatform, game);
    const combined = Math.max(
      0,
      Math.min(1, bestTitle + bestSequel + bestVariant + platform),
    );
    return {
      game,
      title_score: Number(bestTitle.toFixed(3)),
      sequel_score: Number(bestSequel.toFixed(3)),
      variant_score: Number(bestVariant.toFixed(3)),
      platform_score: Number(platform.toFixed(3)),
      combined_confidence: Number(combined.toFixed(3)),
    };
  });

  ranked.sort((a, b) => b.combined_confidence - a.combined_confidence);

  return ranked
    .filter((r) => r.title_score >= 0.30 || r.combined_confidence >= 0.35)
    .slice(0, topK);
}

export function toCandidatesForModel(ranked: RankedCandidate[]): CandidateForModel[] {
  return ranked.map((r) => ({
    game_id: r.game.id,
    title: r.game.title,
    alt_title: r.game.altTitle,
    platform: r.game.platform,
    aliases: r.game.aliases.slice(0, 6),
    publisher: r.game.publisher,
    year: r.game.year,
  }));
}
