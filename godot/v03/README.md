# Ironbound Tactics v0.3

Separate, scene-based JRPG battlefield. Native 4-member formation, 3 opponents, initiative, character HUD, target selection, and expandable combat log. Built for a phone and GitHub headless export.

## Controls

- ATTACK directly asks for a target.
- SKILLS opens Arc Strike.
- MAGIC opens Ember, Frost, and Mend.
- ITEMS opens Potion. Potions are bonus actions **after** a main action, when a target is hurt.
- DEFEND uses your main action and targets yourself.
- EQUIP opens inventory, save, load and restart. Changing gear costs a main action.
- END TURN advances the initiative queue; allies and enemies use AI.

## Architecture

- `systems/unit.gd`: actor state
- `systems/abilities.gd`: legal target definitions
- `systems/battle.gd`: authoritative damage, healing, statuses and initiative
- `systems/ai.gd`: stateless decision making
- `systems/coordinator.gd`: event routing, save/load, AI scheduling
- `presentation/stage.gd`: sprite and VFX presentation, all visual only
- `battle_screen.gd`: touch interface and party bars, target menu and inventory overlay
- `tests/smoke.gd`: regression checks

The party atlas is extracted from user-supplied original sprite art. The VFX atlas is cropped and alpha-converted from user-supplied original effects art. The existing Ashfang dragon icon is custom v0.2 work. No game rules depend on animation callbacks.

`v0.3` uses a distinct package name because this repository currently generates a temporary debug signing key for each build. Long-term updates require secure persistent signing.
