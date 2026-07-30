# experimental/gold_moves_profile_v1

Isolated Flutter spike for **Gold Moves Profile v1.0.0**.

This layer is *experimental*: it is NOT wired into any production screen, it
does NOT read Firestore, and it MUST remain reachable only under
`kDebugMode`. The full findings document lives at
`docs/spikes/gold-moves-profile-v1-flutter.md`.

Layout:

```
domain/       — typed Dart model (sealed unions). No Map<String, dynamic> leaks out.
parsing/      — JSON -> domain, with JSON-path aware ParseError, and SHA-256 verification.
rendering/    — Flutter-independent semantic tokens + text renderers.
presentation/ — Flutter widgets and the debug-only harness screen.
```

The full KOF R-2 profile is treated as a *test fixture only*: it lives
under `doc/move profiles/1.0.0/` and is loaded from disk in tests. It is
NOT declared as a Flutter asset, so no release bundle grows because of
this spike.
