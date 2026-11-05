# Ironbound Chronicles 0.6 — pre-release Android adventure

## What is playable
An end-to-end original 3-chapter fantasy JRPG campaign with animated battles, four party characters (one directly controlled, three AI companions), secure dice, XP and classes, equipment, companion stories, villages, three original biome palettes, NPC dialogue, a quest journal, treasure, repeatable bounty fights, bosses, a shop, upgrades, camps, local audio and three saved adventure slots.

**Chapters:** Hearthwood Vale → Glimmerfen Marsh → Skyvault Citadel.

## How to play
- From the title screen tap **Begin Adventure**.
- Tap the world map or use the directional controls. Walk to the mentor building to accept a quest.
- Defeat the two patrols, defeat the chapter boss, then return to the mentor. Visit the east gate to unlock the next region.
- **Battle:** Choose Attack / Skills / Magic / Items and tap your target. AI companions act automatically.
- **Turn logic:** The game automatically advances when the Warden has spent the regular action and no eligible bonus potion remains. If a potion can heal someone, you may use it or manually end the turn.
- **Victory or defeat:** Automatically returns to the overworld. No EQUIP navigation required.
- **Town / Camp:** Buy potions, forge upgrades, rest, speak to companions, or challenge the Bounty Board.
- **PACK:** Equip or remove gear freely outside combat.
- **JOURNAL:** Review objectives, chapter history, bonds, and achievements.
- **SLOTS:** Save, load and recover one of three local adventure slots.
- **OPTIONS:** Select Story or Veteran difficulty, sound, reduced animation, or start a new campaign.

## Engineering
Gameplay rules, OS-backed secure RNG, world state, campaign progression, inventory, save backup/checksum, audio, hand-illustrated terrain and battle UI are separate modules. Critical interactions have headless tests in GitHub Actions.

**Important:** This is not a paid-store certified release. Real-device QA, release signing, content and privacy compliance and final performance/balance polish are pending. See RELEASE_CHECKLIST.md.
