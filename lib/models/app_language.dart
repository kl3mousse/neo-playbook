/// Supported preferred-language options exposed in the profile UI.
///
/// The [code] is the ISO 639-1 language code stored in Firestore and local
/// preferences. An empty code represents "Default" (i.e. no explicit
/// preference — the app should fall back to the device / app default).
///
/// This list only records the user's preference; the app does not yet
/// translate any UI based on it.
class AppLanguage {
  final String code;
  final String label;

  const AppLanguage({required this.code, required this.label});

  bool get isDefault => code.isEmpty;

  static const AppLanguage defaultLanguage = AppLanguage(
    code: '',
    label: 'Default',
  );

  /// Ordered list shown in the language picker.
  static const List<AppLanguage> all = <AppLanguage>[
    defaultLanguage,
    AppLanguage(code: 'en', label: 'English'),
    AppLanguage(code: 'fr', label: 'French'),
    AppLanguage(code: 'de', label: 'German'),
    AppLanguage(code: 'es', label: 'Spanish'),
    AppLanguage(code: 'pt', label: 'Portuguese'),
    AppLanguage(code: 'ja', label: 'Japanese'),
    AppLanguage(code: 'it', label: 'Italian'),
    AppLanguage(code: 'pl', label: 'Polish'),
    AppLanguage(code: 'no', label: 'Norwegian'),
    AppLanguage(code: 'sv', label: 'Swedish'),
    AppLanguage(code: 'fi', label: 'Finnish'),
    AppLanguage(code: 'ro', label: 'Romanian'),
    AppLanguage(code: 'cs', label: 'Czech'),
  ];

  /// Resolve a stored language code to a known [AppLanguage] entry, falling
  /// back to [defaultLanguage] when the code is empty or not recognised.
  static AppLanguage fromCode(String? code) {
    if (code == null || code.isEmpty) return defaultLanguage;
    for (final lang in all) {
      if (lang.code == code) return lang;
    }
    return defaultLanguage;
  }
}
