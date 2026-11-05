# Ironbound Chronicles: shipping and QA checklist

## Current status
A three-chapter, offline, Android-first JRPG **pre-release**. GitHub Actions performs headless parser, combat rules, world / economy invariants, UI transition and APK export checks. This does not make a game commercially ready on its own.

## Required before selling
1. On-device QA on multiple Android models, screen sizes, orientations and OS versions; test installs, power interruption, backgrounding, save/reload, app updates, accessibility and performance.
2. Playtest battle pacing and difficulty, 3 chapters, side options, loot / economy, all three save slots, all class progressions, every branch and return-to-world behavior.
3. Set up a persistent **release** signing keystore, securely in GitHub Actions secrets, with restricted access, rotation policy and offline recovery. The current workflow deliberately signs debug builds with a fresh ephemeral key.
4. Choose distribution (Google Play / direct sale), register a developer account, configure application identity, target SDK, install channels, pricing, rating, content descriptors, refund policy, tax/payment details.
5. Publish a clear privacy policy. Verify actual data practices: current game has no network permissions and local-only saves. Do not claim policies that were not independently verified.
6. Check original assets and reference-asset provenance, credit / license ownership, font/audio licensing and brand similarity; ensure no third-party copyrighted JRPG assets are present.
7. Create storefront screenshots and trailer from real gameplay, not conceptual promotional art; verify screenshots match shipped features.
8. Support lifecycle: release notes, version migration, crash reporting strategy, customer support, build reproducibility, source backups and rollback paths.

## Gameplay notes
- Warden and 3 AI allies use the existing typed modular combat. Secure OS-backed RNG via Godot Crypto controls damage and critical rolls.
- A finished encounter now returns to the world **without opening Equipment**.
- When the Warden has spent the regular action and no bonus potion is legal, the turn automatically advances. When a potion remains usable, player control is preserved.
- Areas: Hearthwood Vale, Glimmerfen Marsh and Skyvault Citadel.
- Each chapter contains a mentor, two sentinels, a boss, a chest and a forward gate. The final chapter resolves in a credits epilogue.
- Camp rest, merchant potions and forging upgrades, persistent wounds, achievements, class upgrades, 3 save slots and reduced-motion / difficulty controls.
- The save schema is 6 and does **not** silently import v0.5 saves. The v0.6 Android package name intentionally differs from prior debug APKs to prevent signature conflicts.
