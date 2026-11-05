# Ironbound Modular RPG Demo v2

## Modules
- `ModuleActor`: immutable base stats and mutable combat state.
- `ModuleCombat`: authoritative turn/action validation, damage, spells and equipment changes.
- `ModuleAbilityRules`: costs and damage formulas. No direct state mutations.
- `ModuleInventory`: catalog, bag, three equipment slots, bonuses and potion counts. Validation prevents item duplication.
- `ModuleTacticalAI`: pure choices; ally heals low-HP player and enemies cast spells.
- `ModuleSaveStore`: JSON persistence with schema 2; no network or account.
- `ModuleCoordinator`: scene-facing API, event-driven snapshots, combat-to-visual notifications.
- `BattleVisuals`: presentation only. Sprite textures, queued tweens and lightweight burst geometry.
- `main.gd`: touch UI. Two tabs (battle and gear), no per-frame polling.

## Controls
- Regular action: Attack, Arc Strike, Ember Bolt, Frost Shard, Mend, Guard, or change equipment.
- Bonus action: Potion AFTER the regular action, only if injured.
- End Turn: advances dynamic initiative.
- Equipment tab: three slots, item swaps and unequip actions. Equipment changes spend regular action.
- Save/Load: battle, items, equipment, statuses and RNG state stored locally.

## Production follow-ups
- Signing: CI currently creates a new debug key for each build, so Android may require uninstall before installing a later build.
- Save compatibility: schema 2 intentionally does not load the previous schema 1 save.
- Sprite assets are original handmade SVG pixel-style art, not copies of supplied reference images.
- AI and visual effects are deliberately lightweight; more complex battle art and timelines can be added without changing combat rules.
