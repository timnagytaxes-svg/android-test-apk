class_name V3AI
extends RefCounted

# Stateless decision maker. The simulation alone validates and commits actions.
func choose(battle: V3Battle) -> Dictionary:
    var active: V3Unit = battle.active_unit()
    if active == null or active.id == "warden":
        return {}
    var allies: Array[V3Unit] = []
    var foes: Array[V3Unit] = []
    for unit: V3Unit in battle.units:
        if not unit.alive():
            continue
        if unit.faction == active.faction:
            allies.append(unit)
        else:
            foes.append(unit)
    if foes.is_empty():
        return {}
    if active.role in ["cleric", "shaman"] and active.mp >= 2:
        for ally: V3Unit in allies:
            if ally.hp <= battle.max_hp(ally) - 10:
                return {"kind": "mend", "target": ally.id}
    var target: V3Unit = foes[0]
    for foe: V3Unit in foes:
        if foe.hp < target.hp and foe.alive():
            target = foe
    var kind: String = "attack"
    if active.role in ["mage", "warlock"] and active.mp >= 2:
        kind = "ember"
    elif active.role == "rogue" and active.mp >= 2:
        kind = "arc"
    elif active.role == "shaman" and active.mp >= 2:
        kind = "frost"
    return {"kind": kind, "target": target.id}
