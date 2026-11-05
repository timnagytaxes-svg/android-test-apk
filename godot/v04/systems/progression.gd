class_name V4Progression
extends RefCounted

const HEROES: Array[String] = ["warden", "mira", "lyra", "kestrel"]
const CLASSES: Dictionary = {
    "vanguard": {"name": "Vanguard", "hp": 5, "power": 2, "armor": 1, "mp": 0, "skill": "cleave"},
    "spellblade": {"name": "Spellblade", "hp": 0, "power": 1, "armor": 0, "mp": 3, "skill": "surge"},
    "bulwark": {"name": "Bulwark", "hp": 12, "power": 0, "armor": 3, "mp": 0, "skill": "bastion"}
}
var hero_class: String = "vanguard"
var victories: int = 0
# XP is stored *within* the current level, not lifetime XP.
var heroes: Dictionary = {}

func _init() -> void:
    for id: String in HEROES:
        heroes[id] = {"level": 1, "xp": 0}

func xp_needed(level: int) -> int:
    return 30 + (level * 15)

func apply(unit: V3Unit) -> void:
    if not HEROES.has(unit.id):
        return
    var record: Dictionary = heroes[unit.id]
    var level: int = int(record["level"])
    unit.level = level
    unit.experience = int(record["xp"])
    var gained: int = level - 1
    unit.health += gained * 5
    unit.hp = unit.health
    unit.power += gained
    unit.defense += int(gained / 2)
    unit.max_mp += int(gained / 2)
    unit.mp = unit.max_mp
    if unit.id == "warden":
        var class_data: Dictionary = CLASSES[hero_class]
        unit.role = hero_class
        unit.health += int(class_data["hp"])
        unit.hp = unit.health
        unit.power += int(class_data["power"])
        unit.defense += int(class_data["armor"])
        unit.max_mp += int(class_data["mp"])
        unit.mp = unit.max_mp

func earn_victory() -> Array[String]:
    victories += 1
    var messages: Array[String] = []
    var xp_award: int = 55 + (victories - 1) * 5
    for id: String in HEROES:
        var record: Dictionary = heroes[id]
        record["xp"] = int(record["xp"]) + xp_award
        var leveled: bool = false
        while int(record["level"]) < 20 and int(record["xp"]) >= xp_needed(int(record["level"])):
            record["xp"] = int(record["xp"]) - xp_needed(int(record["level"]))
            record["level"] = int(record["level"]) + 1
            leveled = true
        if int(record["level"]) >= 20:
            record["xp"] = mini(int(record["xp"]), xp_needed(20) - 1)
        messages.append("%s +%d XP%s" % [id.capitalize(), xp_award,
            " • LEVEL %d!" % int(record["level"]) if leveled else ""])
    return messages

func change_class(new_class: String) -> bool:
    if not CLASSES.has(new_class):
        return false
    hero_class = new_class
    return true

func to_dict() -> Dictionary:
    return {"hero_class": hero_class, "victories": victories, "heroes": heroes.duplicate(true)}

func restore(data: Dictionary) -> bool:
    var klass: String = str(data.get("hero_class", ""))
    if not CLASSES.has(klass) or not data.get("heroes") is Dictionary:
        return false
    var restored: Dictionary = data["heroes"]
    if restored.size() != HEROES.size():
        return false
    for id: String in HEROES:
        if not restored.has(id) or not restored[id] is Dictionary:
            return false
        var lvl: int = int(restored[id].get("level", 0))
        var xp: int = int(restored[id].get("xp", -1))
        if lvl < 1 or lvl > 20 or xp < 0 or xp >= xp_needed(lvl):
            return false
    var wins: int = int(data.get("victories", -1))
    if wins < 0 or wins > 10000:
        return false
    hero_class = klass
    victories = wins
    heroes = restored.duplicate(true)
    return true
