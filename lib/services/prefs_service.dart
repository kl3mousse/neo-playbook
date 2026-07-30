import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around [SharedPreferences] for app-local state
/// that should survive relaunches but never hit Firestore: filter/sort
/// preferences, recent-game history, note-submit throttle, etc.
///
/// Initialise once from `main()` via [PrefsService.init]. After that,
/// methods are synchronous.
class PrefsService {
  PrefsService._();

  static SharedPreferences? _prefs;
  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('PrefsService.init() was not awaited before use.');
    }
    return p;
  }

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Games list filters ────────────────────────────────────────────

  static const _kPlatform = 'games.platform';
  static const _kSortOption = 'games.sortOption';
  static const _kSortAscending = 'games.sortAscending';
  static const _kFilterGenre = 'games.filter.genre';
  static const _kFilterPublisher = 'games.filter.publisher';
  static const _kFilterPlayers = 'games.filter.players';
  static const _kFilterYearStart = 'games.filter.yearStart';
  static const _kFilterYearEnd = 'games.filter.yearEnd';

  static String? getPlatform() => _p.getString(_kPlatform);
  static Future<void> setPlatform(String? v) =>
      v == null ? _p.remove(_kPlatform) : _p.setString(_kPlatform, v);

  static String? getSortOption() => _p.getString(_kSortOption);
  static Future<void> setSortOption(String v) => _p.setString(_kSortOption, v);

  static bool getSortAscending({bool fallback = true}) =>
      _p.getBool(_kSortAscending) ?? fallback;
  static Future<void> setSortAscending(bool v) =>
      _p.setBool(_kSortAscending, v);

  static String? getFilterGenre() => _p.getString(_kFilterGenre);
  static String? getFilterPublisher() => _p.getString(_kFilterPublisher);
  static int? getFilterPlayers() => _p.getInt(_kFilterPlayers);
  static int? getFilterYearStart() => _p.getInt(_kFilterYearStart);
  static int? getFilterYearEnd() => _p.getInt(_kFilterYearEnd);

  static Future<void> setFilters({
    String? genre,
    String? publisher,
    int? players,
    int? yearStart,
    int? yearEnd,
  }) async {
    await _setOrRemoveString(_kFilterGenre, genre);
    await _setOrRemoveString(_kFilterPublisher, publisher);
    await _setOrRemoveInt(_kFilterPlayers, players);
    await _setOrRemoveInt(_kFilterYearStart, yearStart);
    await _setOrRemoveInt(_kFilterYearEnd, yearEnd);
  }

  static Future<void> _setOrRemoveString(String k, String? v) =>
      v == null || v.isEmpty ? _p.remove(k) : _p.setString(k, v);
  static Future<void> _setOrRemoveInt(String k, int? v) =>
      v == null ? _p.remove(k) : _p.setInt(k, v);

  // ── Recent games ──────────────────────────────────────────────────

  static const _kRecentIds = 'recent.gameIds';
  static const _recentLimit = 10;

  static List<String> getRecentGameIds() =>
      _p.getStringList(_kRecentIds) ?? const <String>[];

  /// Push [gameId] to the front of the list, dedupe, trim to 10.
  static Future<void> pushRecentGame(String gameId) async {
    if (gameId.isEmpty) return;
    final list = getRecentGameIds().toList()
      ..remove(gameId)
      ..insert(0, gameId);
    if (list.length > _recentLimit) list.removeRange(_recentLimit, list.length);
    await _p.setStringList(_kRecentIds, list);
  }

  static Future<void> clearRecentGames() => _p.remove(_kRecentIds);

  // ── Community note throttle ───────────────────────────────────────

  static const _kLastNoteAt = 'notes.lastSubmitMs';
  static const Duration noteCooldown = Duration(seconds: 30);

  /// Remaining cooldown, or [Duration.zero] if the user is allowed to post.
  static Duration noteCooldownRemaining() {
    final last = _p.getInt(_kLastNoteAt);
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    final remaining = noteCooldown.inMilliseconds - elapsed;
    return remaining <= 0 ? Duration.zero : Duration(milliseconds: remaining);
  }

  static Future<void> markNoteSubmitted() =>
      _p.setInt(_kLastNoteAt, DateTime.now().millisecondsSinceEpoch);

  // ── User preferences ──────────────────────────────────────────────

  static const _kPreferredLanguage = 'user.preferredLanguage';

  /// Returns the user's preferred language code (e.g. `'en'`), or `null`
  /// / empty string if no explicit preference is set ("Default").
  static String? getPreferredLanguage() => _p.getString(_kPreferredLanguage);

  /// Persist the user's preferred language code. Pass an empty string to
  /// clear the preference (meaning "Default").
  static Future<void> setPreferredLanguage(String code) => code.isEmpty
      ? _p.remove(_kPreferredLanguage)
      : _p.setString(_kPreferredLanguage, code);

  // ── Default currency ──────────────────────────────────────────────

  static const _kDefaultCurrency = 'user.defaultCurrency';

  /// Returns the user's default currency (e.g. `'EUR'`), or `null` if
  /// the profile has not been loaded yet. Callers should fall back to `'USD'`.
  static String? getDefaultCurrency() => _p.getString(_kDefaultCurrency);

  /// Mirror the default-currency value from the user profile into local prefs
  /// for fast synchronous access.
  static Future<void> setDefaultCurrency(String currency) =>
      _p.setString(_kDefaultCurrency, currency);

  // ── Collection preferences ────────────────────────────────────────

  static const _kCollectionSortOption = 'collection.sortOption';
  static const _kCollapsedPlatforms = 'collection.collapsedPlatforms';

  static String getCollectionSortOption() =>
      _p.getString(_kCollectionSortOption) ?? 'name';

  static Future<void> setCollectionSortOption(String v) =>
      _p.setString(_kCollectionSortOption, v);

  static List<String> getCollapsedPlatforms() =>
      _p.getStringList(_kCollapsedPlatforms) ?? const [];

  static Future<void> setCollapsedPlatforms(List<String> platforms) =>
      _p.setStringList(_kCollapsedPlatforms, platforms);
}
