class_name ModuleInventory
extends RefCounted

const ITEMS: Dictionary = {
    "iron_sword": {"name": "Iron Sword", "slot": "weapon", "power": 2, "armor": 0, "hp": 0, "detail": "Reliable steel blade"},
    "oak_staff": {"name": "Oak Staff", "slot": "weapon", "power": 1, "armor": 0, "hp": 0, "detail": "Caster's focus"},
    "steel_saber": {"name": "Steel Saber", "slot": "weapon", "power": 4, "armor": 0, "hp": 0, "detail": "Sharp and balanced"},
    "leather_coat": {"name": "Leather Coat", "slot": "armor", "power": 0, "armor": 2, "hp": 0, "detail": "Lightweight protection"},
    "scale_mail": {"name": "Scale Mail", "slot": "armor", "power": 0, "armor": 4, "hp": 0, "detail": "Reinforced scales"},
    "sun_charm": {"name": "Sun Charm", "slot": "charm", "power": 0, "armor": 0, "hp": 12, "detail": "Increases maximum HP"},
    "war_pendant": {"name": "War Pendant", "slot": "charm", "power": 1, "armor": 1, "hp": 0, "detail": "Balanced enchantment"}
}
const SLOTS: Array[String] = ["weapon", "armor", "charm"]
var potions: int = 3
var bag: Dictionary = {}
var equipped: Dictionary = {"weapon": "iron_sword", "armor": "", "charm": ""}

func _init() -> void:
    for key: String in ITEMS.keys():
        bag[key] = 0 if key == "iron_sword" else 1

func consume_potion() -> bool:
    if potions < 1:
        return false
    potions -= 1
    return true

func modifiers() -> Dictionary:
    var result: Dictionary = {"power": 0, "armor": 0, "hp": 0}
    for slot: String in SLOTS:
        var item_id: String = str(equipped.get(slot, ""))
        if item_id.is_empty():
            continue
        var item: Dictionary = ITEMS[item_id]
        for stat: String in ["power", "armor", "hp"]:
            result[stat] += int(item[stat])
    return result

func equip(item_id: String) -> bool:
    if not ITEMS.has(item_id) or int(bag.get(item_id, 0)) < 1:
        return false
    var slot: String = str(ITEMS[item_id]["slot"])
    var previous: String = str(equipped.get(slot, ""))
    bag[item_id] = int(bag[item_id]) - 1
    if not previous.is_empty():
        bag[previous] = int(bag[previous]) + 1
    equipped[slot] = item_id
    return true

func unequip(slot: String) -> bool:
    if not SLOTS.has(slot):
        return false
    var item_id: String = str(equipped.get(slot, ""))
    if item_id.is_empty():
        return false
    bag[item_id] = int(bag[item_id]) + 1
    equipped[slot] = ""
    return true

func available_items() -> Array[String]:
    var result: Array[String] = []
    for key: String in ITEMS.keys():
        if int(bag.get(key, 0)) > 0:
            result.append(key)
    return result

func to_dict() -> Dictionary:
    return {"potions": potions, "bag": bag.duplicate(), "equipped": equipped.duplicate()}

func restore(data: Dictionary) -> bool:
    var count: int = int(data.get("potions", -1))
    if count < 0 or count > 99:
        return false
    if not data.has("bag") or not data.has("equipped"):
        return false
    if not data["bag"] is Dictionary or not data["equipped"] is Dictionary:
        return false
    var next_bag: Dictionary = data["bag"]
    var next_equipped: Dictionary = data["equipped"]
    if next_bag.size() != ITEMS.size() or next_equipped.size() != SLOTS.size():
        return false
    for item_id: String in ITEMS.keys():
        if not next_bag.has(item_id):
            return false
        var n: int = int(next_bag[item_id])
        if n < 0 or n > 1:
            return false
        var worn: int = 0
        for slot: String in SLOTS:
            if str(next_equipped.get(slot, "")) == item_id:
                if str(ITEMS[item_id]["slot"]) != slot:
                    return false
                worn += 1
        if n + worn != 1:
            return false
    for slot: String in SLOTS:
        if not next_equipped.has(slot):
            return false
        var worn_id: String = str(next_equipped[slot])
        if not worn_id.is_empty() and not ITEMS.has(worn_id):
            return false
    potions = count
    bag = next_bag.duplicate()
    equipped = next_equipped.duplicate()
    return true
