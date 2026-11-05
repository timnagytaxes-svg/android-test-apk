# Ironbound Tactics v0.5: World & Exploration

A compact event-driven 14x12 tile exploration map with touch pathfinding, optional directional controls, NPC dialogue, a quest chain, a treasure chest, distinct patrol encounters and a multi-foe rift boss. Battle scenes use the existing 4-member party, spell rules, equipment, cryptographic dice and XP. Only one game coordinator is kept for the session.

## Play loop
1. Tap or use arrows to visit Elder Rowan (purple ! at 4,3).
2. Talk to accept the mission.
3. Clear raider (10,3) and shaman (10,8) patrols in tactical battles.
4. Open treasure (3,9) for potions.
5. Defeat Ashfang at (12,10) after the patrols are cleared.
6. Return to Elder Rowan to complete the quest and collect three potions.
7. Save and load overworld progress from the World screen.

Save schema 5 includes world position, objective flags, XP/class progression and items/equipment. Saving is performed in the overworld only, not mid-combat. The battle scene exposes a WORLD button when used by this mode; it only allows returning when the encounter is finished.

No game rules are frame-polled. A pathfinding query happens only when selecting a map tile. Travel uses a short timer while combat and quest state changes are event-driven. The existing v0.3 and v0.4 APK installations are preserved via a separate Android package identifier and save path.
