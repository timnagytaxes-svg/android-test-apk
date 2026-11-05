# Ironbound Tactics v0.4 — Class progression and secure dice

This release introduces three switchable Warden classes (Vanguard, Spellblade, Bulwark), four growing party members, post-victory XP, level-2 class skills, rematches, and OS-backed cryptographically strong combat dice.

Damage is rolled with V4SecureDice, using Godot Crypto.generate_random_bytes and rejection sampling. It is equivalent in intent to Python's secrets.randbelow but works natively in Android. For turn-based combat this small batch of cryptographic entropy has negligible expected device cost. Damage uses 2d6 plus attacker power, skill modifiers, a d20 crit check and armor reductions. Healing also rolls 1d6.

Progression is stored separately from the battle model and applies to the next encounter. Every victory grants XP to all four heroes. Use "NEXT ENCOUNTER" after winning to keep levels and equipment. Class changes chosen in the Equipment / Class screen apply on the next encounter. New Game resets all progress.

v0.4 uses a distinct Android package and save file because the pipeline currently generates a fresh debug signing key. The working v0.3 installation is not overwritten. Deterministic replay is intentionally NOT supported by secure random dice; tests use an injectable dice provider when exact results matter.
