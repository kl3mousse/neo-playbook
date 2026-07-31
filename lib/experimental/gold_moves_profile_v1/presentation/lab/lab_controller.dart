import 'package:flutter/foundation.dart';

import '../../domain/move.dart';
import '../../domain/profile.dart';
import '../gold_rendering_options.dart';

/// Notation displayed in the Lab move card and in the move list.
typedef LabNotation = GoldNotation;

/// Language used by the accessible text renderer inside the Lab.
typedef LabAccessibleLocale = GoldAccessibleLocale;

/// Global theme brightness override for the Lab (does not modify the
/// user's global preferences).
enum LabThemeMode { dark, light, system }

/// Vertical density for the move list.
typedef LabDensity = GoldDensity;

/// Discrete simulated text-scale values available in the Lab.
enum LabTextScale { s100, s130, s160, s200 }

extension LabTextScaleX on LabTextScale {
  double get factor => switch (this) {
    LabTextScale.s100 => 1.0,
    LabTextScale.s130 => 1.3,
    LabTextScale.s160 => 1.6,
    LabTextScale.s200 => 2.0,
  };

  int get percent => switch (this) {
    LabTextScale.s100 => 100,
    LabTextScale.s130 => 130,
    LabTextScale.s160 => 160,
    LabTextScale.s200 => 200,
  };
}

/// Move-list filter mode.
enum LabMoveFilter { all, automaticOnly }

/// Reactive state container for the Gold Move Lab. Held above the
/// screen tree so tabs and the settings sheet share the same source of
/// truth without any global singleton.
class LabController extends ChangeNotifier {
  LabController(this._profile);

  final ProfileGold _profile;
  ProfileGold get profile => _profile;

  // Selection ----------------------------------------------------

  String? _selectedCharacterId;
  String? get selectedCharacterId => _selectedCharacterId;

  String? _selectedMoveId;
  String? get selectedMoveId => _selectedMoveId;

  void selectCharacter(String? id) {
    if (_selectedCharacterId == id) return;
    _selectedCharacterId = id;
    // Reset move selection when the character changes.
    _selectedMoveId = null;
    notifyListeners();
  }

  void selectMove(String? id) {
    if (_selectedMoveId == id) return;
    _selectedMoveId = id;
    notifyListeners();
  }

  // Filters ------------------------------------------------------

  String _search = '';
  String get search => _search;
  void setSearch(String q) {
    if (_search == q) return;
    _search = q;
    notifyListeners();
  }

  LabMoveFilter _moveFilter = LabMoveFilter.all;
  LabMoveFilter get moveFilter => _moveFilter;
  void setMoveFilter(LabMoveFilter f) {
    if (_moveFilter == f) return;
    _moveFilter = f;
    notifyListeners();
  }

  bool _groupByCategory = false;
  bool get groupByCategory => _groupByCategory;
  void setGroupByCategory(bool v) {
    if (_groupByCategory == v) return;
    _groupByCategory = v;
    notifyListeners();
  }

  // Rendering ---------------------------------------------------

  LabNotation _notation = LabNotation.pictograms;
  LabNotation get notation => _notation;
  void setNotation(LabNotation n) {
    if (_notation == n) return;
    _notation = n;
    notifyListeners();
  }

  LabAccessibleLocale _accessibleLocale = LabAccessibleLocale.en;
  LabAccessibleLocale get accessibleLocale => _accessibleLocale;
  void setAccessibleLocale(LabAccessibleLocale l) {
    if (_accessibleLocale == l) return;
    _accessibleLocale = l;
    notifyListeners();
  }

  LabThemeMode _themeMode = LabThemeMode.dark;
  LabThemeMode get themeMode => _themeMode;
  void setThemeMode(LabThemeMode t) {
    if (_themeMode == t) return;
    _themeMode = t;
    notifyListeners();
  }

  LabDensity _density = LabDensity.comfortable;
  LabDensity get density => _density;
  void setDensity(LabDensity d) {
    if (_density == d) return;
    _density = d;
    notifyListeners();
  }

  LabTextScale _textScale = LabTextScale.s100;
  LabTextScale get textScale => _textScale;
  void setTextScale(LabTextScale s) {
    if (_textScale == s) return;
    _textScale = s;
    notifyListeners();
  }

  // Derived queries ---------------------------------------------

  /// Moves belonging to a character (preserved in editorial order).
  List<MoveGold> movesForCharacter(String characterId) {
    return _profile.movesForCharacter(characterId).toList();
  }

  /// Filtered moves for a character honoring [search] and [moveFilter].
  List<MoveGold> filteredMovesForCharacter(String characterId) {
    final all = movesForCharacter(characterId);
    final q = _search.trim().toLowerCase();
    return all.where((m) {
      if (_moveFilter == LabMoveFilter.automaticOnly &&
          m.activation.kind != ActivationKind.automaticAfterMove) {
        return false;
      }
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          (m.rawCategory.toLowerCase().contains(q));
    }).toList();
  }

  /// All moves matching the current filters, across every character.
  List<MoveGold> filteredMovesAcrossProfile() {
    final q = _search.trim().toLowerCase();
    return _profile.moves.where((m) {
      if (_moveFilter == LabMoveFilter.automaticOnly &&
          m.activation.kind != ActivationKind.automaticAfterMove) {
        return false;
      }
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.rawCategory.toLowerCase().contains(q);
    }).toList();
  }

  Map<ActivationKind, int> activationCounts() {
    final out = <ActivationKind, int>{};
    for (final m in _profile.moves) {
      out[m.activation.kind] = (out[m.activation.kind] ?? 0) + 1;
    }
    return out;
  }
}
