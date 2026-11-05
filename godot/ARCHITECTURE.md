# Modular Android RPG slice

The playable slice exercises all six independent concerns:
- Character: `ModuleActor` owns stats, action flags, and healing/damage primitives.
- Combat: `ModuleCombat` is the only orchestrator that may change battle state.
- Abilities: `ModuleAbilityRules` calculates damage without mutating state.
- Tactical AI: `ModuleTacticalAI` returns action choices, never edits actors.
- Inventory: `ModuleInventory` owns shared potion counts.
- Persistence: `ModuleSaveStore` owns JSON file I/O and nothing else.

`ModuleCoordinator` connects the modules once, publishes event-driven view snapshots, and schedules non-player turns using deferred calls. `main.gd` is presentation-only: it never modifies combatants.

## Manual smoke test
Start battle. Tap Potion first (unavailable). Use Arc Strike (consumes SP).
Attack is now disabled, but End Turn works. Ashfang and Mira act automatically.
Next round, Attack then Potion heals the Warden and consumes one item.
Save, restart, load: HP, items, the current turn and action flags are restored.

## Debug policy
No per-frame scene tree scanning, polling, or global autoload singleton. State changes emit one `changed` signal. Tests run headlessly on each APK build.
