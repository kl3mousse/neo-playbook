/**
 * Final ranking + calibrated auto-accept rules.
 *
 * Internal `combined_confidence` is mapped to a value the Flutter app
 * can act on without changes:
 *
 *  - autoAccept                -> confidence >= 0.85
 *  - pick + needs confirmation -> confidence in [0.45, 0.84]  (app shows top matches)
 *  - very weak / no match      -> confidence  <  0.45         (app auto-drafts unverified)
 *
 * The Flutter side already uses `combined_confidence < 0.45` as the
 * low-confidence trigger, so this preserves backward compatibility.
 */

import { DbConstrainedSelection, RankedCandidate } from "./types";
import { normalizeText } from "./text";

const AUTO_ACCEPT_CONFIDENCE = 0.82;
const AUTO_ACCEPT_GAP = 0.12;
const APP_LOW_CONFIDENCE_FLOOR = 0.45;

export type FinalRanked = {
  ranked: RankedCandidate[];
  selectedGameId: string | null;
  topConfidence: number;
  needsUserConfirmation: boolean;
  evidence: string;
  rejectedCloseCandidates: string[];
  autoAccepted: boolean;
};

export function finalizeRanking(
  ranked: RankedCandidate[],
  selection: DbConstrainedSelection | undefined,
): FinalRanked {
  if (ranked.length === 0) {
    return {
      ranked: [],
      selectedGameId: null,
      topConfidence: 0,
      needsUserConfirmation: true,
      evidence: selection?.evidence ?? "",
      rejectedCloseCandidates: selection?.rejected_close_candidates ?? [],
      autoAccepted: false,
    };
  }

  // Validate the model's selected_game_id is actually in our retrieval list.
  const candidateIds = new Set(ranked.map((r) => r.game.id));
  const safeSelectedId = selection?.selected_game_id && candidateIds.has(selection.selected_game_id)
    ? selection.selected_game_id
    : null;
  const modelConf = selection?.confidence ?? 0;
  const evidence = selection?.evidence ?? "";
  const rejected = (selection?.rejected_close_candidates ?? []).filter((id) => candidateIds.has(id));

  for (const r of ranked) {
    let boost = 0;
    if (safeSelectedId && r.game.id === safeSelectedId) {
      boost += 0.18 * modelConf;
      if (evidence) {
        const text = normalizeText(evidence);
        if (text && r.game.normalizedTitle && text.includes(r.game.normalizedTitle)) {
          boost += 0.06; // OCR-style exact title match in evidence
        }
      }
      r.selected_by_model = true;
      r.evidence = evidence;
    } else if (rejected.includes(r.game.id)) {
      boost -= 0.05;
      r.rejected_by_model = true;
    }
    r.combined_confidence = Number(
      Math.max(0, Math.min(1, r.combined_confidence + boost)).toFixed(3),
    );
  }

  ranked.sort((a, b) => b.combined_confidence - a.combined_confidence);

  const top = ranked[0];
  const second = ranked[1];
  const gap = top.combined_confidence - (second?.combined_confidence ?? 0);
  const hasEvidence = evidence.length > 2;

  const autoAccept =
    selection != null &&
    safeSelectedId === top.game.id &&
    selection.needs_user_confirmation === false &&
    selection.confidence >= AUTO_ACCEPT_CONFIDENCE &&
    top.combined_confidence >= AUTO_ACCEPT_CONFIDENCE &&
    gap >= AUTO_ACCEPT_GAP &&
    hasEvidence;

  let topConfidence = top.combined_confidence;
  if (autoAccept) {
    topConfidence = Math.max(topConfidence, 0.85);
  } else if (topConfidence < APP_LOW_CONFIDENCE_FLOOR && safeSelectedId === top.game.id && hasEvidence) {
    // We have a model-supported pick but retrieval scored it low — keep it
    // above the low-confidence floor so the app shows the matches list
    // for confirmation instead of silently auto-drafting an unverified item.
    topConfidence = APP_LOW_CONFIDENCE_FLOOR;
  }

  ranked[0] = { ...top, combined_confidence: Number(topConfidence.toFixed(3)) };

  return {
    ranked: ranked.slice(0, 3),
    selectedGameId: autoAccept ? top.game.id : null,
    topConfidence: Number(topConfidence.toFixed(3)),
    needsUserConfirmation: !autoAccept,
    evidence,
    rejectedCloseCandidates: rejected,
    autoAccepted: autoAccept,
  };
}
