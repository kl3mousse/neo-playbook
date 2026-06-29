/**
 * Shared types for the collection-scan recognition pipeline.
 */

export type RecognitionMode = "ownership_check" | "bulk_import";

export type ItemType =
  | "box"
  | "cartridge"
  | "pcb"
  | "disc"
  | "marquee"
  | "flyer"
  | "manual"
  | "spine"
  | "shelf"
  | "unknown";

export type BoundingBox = {
  x: number;
  y: number;
  width: number;
  height: number;
};

/** First-pass output: pure visual evidence per detected item. */
export type ExtractedItem = {
  candidate_id: string;
  visible_text: string;
  visible_text_lines: string[];
  platform_hints: string[];
  item_type: ItemType;
  raw_title_hint: string;
  uncertainty_reason: string;
  bounding_box: BoundingBox | null;
};

export type VisualExtractionResult = {
  scene_summary: string;
  estimated_item_count: number;
  items: ExtractedItem[];
};

/** Compact catalog entry shown to the matcher model. */
export type CandidateForModel = {
  game_id: string;
  title: string;
  alt_title: string | null;
  platform: string;
  aliases: string[];
  publisher: string | null;
  year: number | null;
};

/** Second-pass output per item. selected_game_id MUST come from the candidate list. */
export type DbConstrainedSelection = {
  candidate_id: string;
  selected_game_id: string | null;
  confidence: number;
  evidence: string;
  rejected_close_candidates: string[];
  needs_user_confirmation: boolean;
};

export type DbConstrainedMatchResult = {
  selections: DbConstrainedSelection[];
};

/** Indexed catalog entry held in the in-memory cache. */
export type GameCandidate = {
  id: string;
  title: string;
  altTitle: string | null;
  platform: string;
  platformNormalized: string;
  publisher: string | null;
  year: number | null;
  aliases: string[];
  searchTokens: string[];
  ngrams: Set<string>;
  normalizedTitle: string;
  normalizedAltTitles: string[];
  sequelNumber: number | null;
  coverImageUrl: string | null;
};

/** Output of the retriever (top-K per item, before model selection). */
export type RankedCandidate = {
  game: GameCandidate;
  title_score: number;
  sequel_score: number;
  variant_score: number;
  platform_score: number;
  combined_confidence: number;
  evidence?: string;
  selected_by_model?: boolean;
  rejected_by_model?: boolean;
};
