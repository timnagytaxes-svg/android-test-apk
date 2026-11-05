class_name V3Abilities
extends RefCounted

const DATA: Dictionary = {
    "attack": {"name": "Attack", "cost": 0, "type": "damage", "target": "foe", "style": "slash"},
    "arc": {"name": "Arc Strike", "cost": 2, "type": "damage", "target": "foe", "style": "arc"},
    "ember": {"name": "Ember Bolt", "cost": 2, "type": "damage", "target": "foe", "style": "fire"},
    "frost": {"name": "Frost Shard", "cost": 2, "type": "damage", "target": "foe", "style": "ice"},
    "mend": {"name": "Mend", "cost": 2, "type": "heal", "target": "ally", "style": "heal"},
    "guard": {"name": "Defend", "cost": 0, "type": "guard", "target": "self", "style": "guard"},
    "potion": {"name": "Potion", "cost": 0, "type": "heal", "target": "ally", "style": "heal", "bonus": true}
}

func definition(kind: String) -> Dictionary:
    return DATA.get(kind, {})

func targets(kind: String, actor: V3Unit, actors: Array[V3Unit]) -> Array[String]:
    var possible: Array[String] = []
    var action: Dictionary = definition(kind)
    var target_type: String = str(action.get("target", ""))
    for unit: V3Unit in actors:
        if not unit.alive():
            continue
        if target_type == "foe" and unit.faction != actor.faction:
            possible.append(unit.id)
        elif target_type == "ally" and unit.faction == actor.faction:
            possible.append(unit.id)
        elif target_type == "self" and unit.id == actor.id:
            possible.append(unit.id)
    return possible
