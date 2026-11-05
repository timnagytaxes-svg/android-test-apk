class_name V6Campaign
extends RefCounted

signal changed(message: String)

const CHAPTERS: int = 3
const CLASSIC_DIFFICULTY: int = 0
const VETERAN_DIFFICULTY: int = 1

var zones: Array[V6ZoneWorld] = []
var chapter: int = 0
var gold: int = 80
var crystals: int = 0
var forge_power: int = 0
var forge_armor: int = 0
var difficulty: int = CLASSIC_DIFFICULTY
var reduced_motion: bool = false
var sound_enabled: bool = true
var encounters_won: int = 0
var encounters_lost: int = 0
var treasures_found: int = 0
var party_wounds: Dictionary = {}
var _dice := V4SecureDice.new()
var achievements: Array[String] = []
var bonds: Dictionary = {"mira": 0, "lyra": 0, "kestrel": 0}
var stories := V6CompanionStories.new()

func _init() -> void:
    for index: int in range(CHAPTERS):
        zones.append(V6ZoneWorld.new(index))

func current_zone() -> V6ZoneWorld:
    return zones[chapter]

func travel(next_chapter: int) -> bool:
    if next_chapter < 0 or next_chapter >= CHAPTERS or abs(next_chapter-chapter) != 1:
        return false
    if next_chapter > chapter and not current_zone().portal_ready():
        return false
    chapter = next_chapter
    changed.emit("You enter %s." % V6ZoneWorld.ZONE_DATA[chapter]["name"])
    return true

func apply_battle_modifiers(battle: V3Battle) -> void:
    if battle == null:
        return
    var hero: V3Unit = battle.unit_by_id("warden")
    if hero != null:
        hero.power += forge_power * 2
        hero.defense += forge_armor * 2
    for unit: V3Unit in battle.units:
        if unit.faction == "party":
            if bonds.has(unit.id):
                unit.power += int(bonds[unit.id]) / 2
                unit.max_mp += int(bonds[unit.id]) / 2
                unit.mp = mini(unit.max_mp,unit.mp + int(bonds[unit.id]) / 2)
            unit.hp = maxi(1, battle.max_hp(unit) - int(party_wounds.get(unit.id, 0)))
        elif unit.alive() and difficulty == VETERAN_DIFFICULTY:
            unit.power += 2
            unit.health += 12
            unit.hp += 12

func record_battle(encounter: String, victory: bool, battle: V3Battle) -> Dictionary:
    if victory:
        encounters_won += 1
        var reward: int = 20 + chapter * 15 + _dice.between(5, 20)
        if encounter == "boss":
            reward += 65
            crystals += 2
        else:
            crystals += 1
        gold += reward
        for actor: V3Unit in battle.units:
            if actor.faction == "party":
                var missing: int = maxi(0, battle.max_hp(actor) - actor.hp)
                if missing > 0:
                    party_wounds[actor.id] = missing
                else:
                    party_wounds.erase(actor.id)
        _award_badge("first_victory")
        if encounter == "boss":
            _award_badge("boss_slayer")
        if chapter == 2 and encounter == "boss":
            _award_badge("stars_reclaimed")
        changed.emit("Victory! +%d gold, +%d crystal%s. Your party keeps its wounds until camp." % [
            reward, 2 if encounter == "boss" else 1, "s" if encounter == "boss" else ""])
        return {"gold": reward, "crystals": 2 if encounter == "boss" else 1}
    encounters_lost += 1
    var lost: int = mini(gold, 15 + chapter * 5)
    gold -= lost
    party_wounds.clear()
    changed.emit("Your party was rescued and restored at camp. Lost %d gold." % lost)
    return {"gold": -lost, "crystals": 0}

func shop_purchase(product: String, bag: ModuleInventory) -> bool:
    var cost: int = 0
    match product:
        "potion": cost = 24
        "bundle": cost = 66
        "forge_power": cost = 90 + forge_power * 70
        "forge_armor": cost = 90 + forge_armor * 70
        "rest": cost = 15
        _: return false
    if gold < cost:
        changed.emit("Not enough gold. Need %d gold." % cost)
        return false
    if product in ["forge_power","forge_armor"] and crystals < 2:
        changed.emit("The forge needs two Rift Crystals.")
        return false
    if product == "forge_power" and forge_power >= 4:
        return false
    if product == "forge_armor" and forge_armor >= 4:
        return false
    if product == "potion" and bag.potions >= 99:
        return false
    if product == "bundle" and bag.potions > 96:
        return false
    if product == "rest" and party_wounds.is_empty():
        changed.emit("Your party is already rested.")
        return false
    gold -= cost
    match product:
        "potion":
            bag.potions += 1
            changed.emit("Purchased one potion.")
        "bundle":
            bag.potions += 3
            changed.emit("Purchased three potions.")
        "forge_power":
            crystals -= 2
            forge_power += 1
            _award_badge("first_forge")
            changed.emit("Weapon forged! Permanent +%d power in new battles." % (forge_power * 2))
        "forge_armor":
            crystals -= 2
            forge_armor += 1
            _award_badge("first_forge")
            changed.emit("Armor forged! Permanent +%d armor in new battles." % (forge_armor * 2))
        "rest":
            party_wounds.clear()
            changed.emit("The party rests at camp, recovering fully.")
    return true

func camp_conversation(actor_id: String) -> Dictionary:
    var dialogue: Dictionary = stories.conversation(actor_id, chapter)
    if dialogue.is_empty():
        return {}
    if int(bonds.get(actor_id, 0)) < chapter + 1:
        bonds[actor_id] = chapter + 1
        changed.emit("%s's trust deepens. Their battle affinity has grown." % actor_id.capitalize())
    if int(bonds["mira"]) >= 1 and int(bonds["lyra"]) >= 1 and int(bonds["kestrel"]) >= 1:
        _award_badge("party_bonds")
    return dialogue

func _award_badge(id: String) -> void:
    if not achievements.has(id):
        achievements.append(id)

func journal() -> String:
    var lines: PackedStringArray = ["IRONBOUND CHRONICLES", ""]
    for index: int in range(CHAPTERS):
        var data: Dictionary = V6ZoneWorld.ZONE_DATA[index]
        var zone: V6ZoneWorld = zones[index]
        lines.append("CHAPTER %d: %s" % [index+1, data["name"]])
        if index > chapter:
            lines.append("  Locked until the preceding chapter is completed.")
        else:
            lines.append("  " + zone.objective_text())
        lines.append("")
    lines.append("COMPANION BONDS")
    for id: String in bonds.keys():
        lines.append("  %s: Chapter %d bond" % [id.capitalize(),int(bonds[id])])
    lines.append("")
    lines.append("WORLD STATS")
    lines.append("  Victories: %d    Defeats: %d" % [encounters_won, encounters_lost])
    lines.append("  Gold: %d    Rift Crystals: %d" % [gold, crystals])
    lines.append("  Weapon forging: %d / 4    Armor forging: %d / 4" % [forge_power, forge_armor])
    lines.append("")
    lines.append("ACHIEVEMENTS: %s" % (", ".join(PackedStringArray(achievements)) if not achievements.is_empty() else "None"))
    return "\n".join(lines)

func completed() -> bool:
    return zones[2].quest_claimed

func to_dict() -> Dictionary:
    var states: Array[Dictionary] = []
    for zone: V6ZoneWorld in zones:
        states.append(zone.to_dict())
    return {"schema": 1, "chapter": chapter, "gold": gold, "crystals": crystals,
        "forge_power": forge_power, "forge_armor": forge_armor,
        "difficulty": difficulty, "reduced_motion": reduced_motion, "sound_enabled": sound_enabled,
        "encounters_won": encounters_won, "encounters_lost": encounters_lost,
        "treasures_found": treasures_found, "party_wounds": party_wounds.duplicate(),
        "achievements": achievements.duplicate(), "bonds": bonds.duplicate(), "zones": states}

func restore(data: Dictionary) -> bool:
    if int(data.get("schema",0)) != 1 or not data.get("zones") is Array or data["zones"].size() != CHAPTERS:
        return false
    var n: int = int(data.get("chapter",-1))
    if n < 0 or n >= CHAPTERS:
        return false
    var numeric: Array[String] = ["gold", "crystals", "forge_power", "forge_armor", "encounters_won", "encounters_lost"]
    for field: String in numeric:
        var value: int = int(data.get(field,-1))
        if value < 0 or value > 1000000:
            return false
    if int(data["forge_power"]) > 4 or int(data["forge_armor"]) > 4:
        return false
    if not data.get("party_wounds") is Dictionary or not data.get("achievements") is Array or not data.get("bonds") is Dictionary:
        return false
    var saved_wounds: Dictionary = data["party_wounds"]
    for id: String in saved_wounds.keys():
        if id not in ["warden","mira","lyra","kestrel"] or int(saved_wounds[id]) < 0 or int(saved_wounds[id]) > 999:
            return false
    var saved_bonds: Dictionary = data["bonds"]
    if saved_bonds.size() != 3:
        return false
    for id: String in ["mira","lyra","kestrel"]:
        if not saved_bonds.has(id) or int(saved_bonds[id]) < 0 or int(saved_bonds[id]) > 3:
            return false
    var new_zones: Array[V6ZoneWorld] = []
    for i: int in range(CHAPTERS):
        if not data["zones"][i] is Dictionary:
            return false
        var z := V6ZoneWorld.new(i)
        if not z.restore(data["zones"][i]):
            return false
        if i > 0 and (z.quest_started or z.quest_claimed) and not new_zones[i-1].quest_claimed:
            return false
        new_zones.append(z)
    if n > 0 and not new_zones[n-1].quest_claimed:
        return false
    var mode: int = int(data.get("difficulty",-1))
    if mode not in [CLASSIC_DIFFICULTY, VETERAN_DIFFICULTY]:
        return false
    zones = new_zones
    chapter = n
    gold = int(data["gold"])
    crystals = int(data["crystals"])
    forge_power = int(data["forge_power"])
    forge_armor = int(data["forge_armor"])
    encounters_won = int(data["encounters_won"])
    encounters_lost = int(data["encounters_lost"])
    treasures_found = maxi(0, int(data.get("treasures_found",0)))
    difficulty = mode
    reduced_motion = bool(data.get("reduced_motion",false))
    sound_enabled = bool(data.get("sound_enabled",true))
    party_wounds = saved_wounds.duplicate()
    bonds = saved_bonds.duplicate()
    achievements.clear()
    for item: Variant in data["achievements"]:
        var key: String = str(item)
        if not achievements.has(key) and key in ["first_victory", "boss_slayer", "first_forge", "stars_reclaimed", "treasure_hunter", "party_bonds"]:
            achievements.append(key)
    return true
