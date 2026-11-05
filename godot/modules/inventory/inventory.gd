class_name ModuleInventory
extends RefCounted

var potions: int = 2

func consume_potion() -> bool:
    if potions <= 0:
        return false
    potions -= 1
    return true

func to_dict() -> Dictionary:
    return {"potions": potions}

func restore(data: Dictionary) -> bool:
    var count: int = int(data.get("potions", -1))
    if count < 0 or count > 99:
        return false
    potions = count
    return true
