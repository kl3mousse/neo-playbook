/// Lightweight currency conversion using bundled approximate exchange rates.
///
/// These are static rates relative to USD. They are intentionally approximate
/// and are used only for display-only portfolio totals. Individual item prices
/// are always stored and shown in their original currency.
///
/// Rates should be updated periodically (a few times a year is fine for this
/// use-case). The [ratesNote] string is shown to users so they understand the
/// limitation.
class CurrencyService {
  CurrencyService._();

  // ── Static rate table (relative to 1 USD) ───────────────────────────────
  // Last updated: 2025-07
  static const Map<String, double> _ratesFromUsd = {
    'USD': 1.00,
    'EUR': 0.92,
    'JPY': 157.00,
    'GBP': 0.79,
  };

  /// Human-readable note about the rate source, shown in the UI.
  static const String ratesNote =
      'Approximate rates as of 2025-07. '
      'For display only — individual prices are in their original currency.';

  /// Whether [currency] has a known rate.
  static bool isKnown(String currency) =>
      _ratesFromUsd.containsKey(currency.toUpperCase());

  /// Convert [amount] from [from] to [to].
  ///
  /// Returns `null` if either currency is unknown (unknown currencies are
  /// silently excluded from converted totals).
  static double? convert(double amount, String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return amount;
    final fromRate = _ratesFromUsd[from.toUpperCase()];
    final toRate = _ratesFromUsd[to.toUpperCase()];
    if (fromRate == null || toRate == null) return null;
    // Convert via USD as pivot.
    return (amount / fromRate) * toRate;
  }

  /// Compute a converted grand total from a per-currency totals map.
  ///
  /// Returns a [ConvertedTotal] describing the result and whether any
  /// amounts were skipped (unknown currencies).
  static ConvertedTotal convertTotals(
    Map<String, double> currencyTotals,
    String targetCurrency,
  ) {
    if (currencyTotals.isEmpty) {
      return ConvertedTotal(total: 0, currency: targetCurrency, isExact: true);
    }

    // If all amounts are already in the target currency → exact total.
    if (currencyTotals.length == 1 &&
        currencyTotals.keys.first.toUpperCase() ==
            targetCurrency.toUpperCase()) {
      return ConvertedTotal(
        total: currencyTotals.values.first,
        currency: targetCurrency,
        isExact: true,
      );
    }

    double sum = 0;
    bool hasUnknown = false;
    final breakdown = <String>[];

    for (final entry in currencyTotals.entries) {
      final converted = convert(entry.value, entry.key, targetCurrency);
      if (converted != null) {
        sum += converted;
        if (entry.key.toUpperCase() != targetCurrency.toUpperCase()) {
          breakdown.add('${entry.value.toStringAsFixed(0)} ${entry.key}');
        }
      } else {
        hasUnknown = true;
        breakdown.add(
          '${entry.value.toStringAsFixed(0)} ${entry.key} (not converted)',
        );
      }
    }

    return ConvertedTotal(
      total: sum,
      currency: targetCurrency,
      isExact: false, // approximate because conversion was applied
      hasUnknownCurrencies: hasUnknown,
      breakdown: breakdown,
    );
  }
}

/// Result of a currency conversion operation.
class ConvertedTotal {
  /// The converted (or summed) amount in [currency].
  final double total;

  /// The display currency.
  final String currency;

  /// True when no conversion was needed (all amounts were already in [currency]).
  final bool isExact;

  /// True if at least one source currency had no known rate and was excluded.
  final bool hasUnknownCurrencies;

  /// Per-currency breakdown strings, for use in a tooltip.
  final List<String> breakdown;

  const ConvertedTotal({
    required this.total,
    required this.currency,
    this.isExact = true,
    this.hasUnknownCurrencies = false,
    this.breakdown = const [],
  });

  /// Formatted display string, e.g. `"≈ 1 234 EUR"` or `"1 234 USD"`.
  String get displayValue {
    final formatted = total.toStringAsFixed(0);
    return isExact ? '$formatted $currency' : '≈ $formatted $currency';
  }

  /// Tooltip text combining the breakdown lines and the rates disclaimer.
  String? get tooltipText {
    if (isExact && !hasUnknownCurrencies) return null;
    final lines = <String>[];
    if (breakdown.isNotEmpty) lines.addAll(breakdown);
    lines.add(CurrencyService.ratesNote);
    return lines.join('\n');
  }
}
