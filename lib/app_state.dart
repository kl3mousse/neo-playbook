import 'package:flutter/foundation.dart';

/// Becomes `true` once the splash sequence completes. Set back to `false`
/// to replay the intro (e.g. from the profile screen).
final ValueNotifier<bool> splashFinished = ValueNotifier<bool>(false);
