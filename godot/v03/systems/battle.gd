class_name V3Battle
extends RefCounted

signal changed(message: String)
signal action_resolved(event: Dictionary)

var units: Array[V3Unit] = []
var order: Array[String] = []
var index: int = 0
var round: int = 1
var finished: bool = false
var result: String = ""
var inventory: ModuleInventory
var abilities := V3Abilities.new()
var rng := RandomNumberGenerator.new()

func _init(bag: ModuleInventory) -> void:
    inventory = bag

func create() -> void:
    units = [
        V3Unit.new("warden", "Warden", "party", "warrior", 42, 6, 3, 12, 4),
        V3Unit.new("mira", "Mira", "party", "cleric", 31, 4, 1, 9, 5),
        V3Unit.new("lyra", "Lyra", "party", "mage", 26, 4, 1, 11, 6),
        V3Unit.new("kestrel", "Kestrel", "party", "rogue", 29, 5, 2, 15, 4),
        V3Unit.new("ashfang", "Ashfang", "enemy", "dragon", 95, 8, 3, 8, 5),
        V3Unit.new("raider", "Ash Raider", "enemy", "raider", 33, 5, 1, 10, 3),
        V3Unit.new("shaman", "Ash Shaman", "enemy", "shaman", 30, 4, 1, 7, 4)
    ]
    round = 1
    index = 0
    finished = false
    result = ""
    rng.randomize()
    _reorder()
    active_unit().begin_turn()
    changed.emit("The party confronts Ashfang and his retainers!")

func unit_by_id(key: String) -> V3Unit:
    for unit: V3Unit in units:
        if unit.id == key:
            return unit
    return null

func active_unit() -> V3Unit:
    if finished or order.is_empty():
        return null
    return unit_by_id(order[index])

func max_hp(unit: V3Unit) -> int:
    return unit.health + (int(inventory.modifiers()["hp"]) if unit.id == "warden" else 0)

func attack_power(unit: V3Unit) -> int:
    return unit.power + (int(inventory.modifiers()["power"]) if unit.id == "warden" else 0)

func armor(unit: V3Unit) -> int:
    return unit.defense + (int(inventory.modifiers()["armor"]) if unit.id == "warden" else 0)

func can_act(kind: String, target_id: String = "") -> bool:
    var actor: V3Unit = active_unit()
    if actor == null or not actor.alive():
        return false
    var definition: Dictionary = abilities.definition(kind)
    if definition.is_empty():
        return false
    var is_bonus: bool = bool(definition.get("bonus", false))
    if is_bonus:
        if not actor.action_used or actor.bonus_used or inventory.potions < 1:
            return false
    elif actor.action_used:
        return false
    if actor.mp < int(definition["cost"]):
        return false
    if target_id.is_empty():
        return not abilities.targets(kind, actor, units).is_empty()
    var target: V3Unit = unit_by_id(target_id)
    if target == null or not abilities.targets(kind, actor, units).has(target_id):
        return false
    if kind in ["mend", "potion"] and target.hp >= max_hp(target):
        return false
    return true

func execute(kind: String, target_id: String) -> bool:
    if not can_act(kind, target_id):
        return false
    var actor: V3Unit = active_unit()
    var target: V3Unit = unit_by_id(target_id)
    var definition: Dictionary = abilities.definition(kind)
    if bool(definition.get("bonus", false)):
        if not inventory.consume_potion():
            return false
        actor.bonus_used = true
    else:
        actor.action_used = true
    actor.mp -= int(definition["cost"])
    var amount: int = 0
    if kind == "guard":
        actor.guarding = true
    elif kind in ["mend", "potion"]:
        amount = target.heal(14 if kind == "potion" else (13 + rng.randi_range(0, 4)), max_hp(target))
    else:
        var base: int = 3 + attack_power(actor) + rng.randi_range(0, 4)
        if kind == "arc":
            base += 6
        elif kind == "ember":
            base += 5
        elif kind == "frost":
            base += 2
        if actor.chilled > 0:
            base -= 2
        var mitigation: int = armor(target)
        if kind in ["ember", "frost"]:
            mitigation = int(ceil(float(mitigation) * 0.5))
        if target.guarding:
            base -= 5
        amount = target.hurt(maxi(1, base - mitigation))
        if kind == "frost" and target.alive():
            target.chilled = 2
    actor.chilled = maxi(0, actor.chilled - 1)
    _check_end()
    action_resolved.emit({"kind": kind, "style": str(definition["style"]), "source": actor.id,
        "target": target.id, "amount": amount, "healing": kind in ["mend", "potion"]})
    var verb: String = "recovers" if kind in ["mend", "potion"] else "deals"
    var summary: String = "%s: %s on %s (%s %d)." % [actor.name, definition["name"], target.name, verb, amount]
    if kind == "guard":
        summary = "%s braces against incoming attacks." % actor.name
    if finished:
        summary += " " + result
    changed.emit(summary)
    return true

func change_gear(item_id: String, slot: String, wearing: bool) -> bool:
    var actor: V3Unit = active_unit()
    if actor == null or actor.id != "warden" or actor.action_used:
        return false
    var success: bool = inventory.equip(item_id) if wearing else inventory.unequip(slot)
    if not success:
        return false
    actor.hp = mini(actor.hp, max_hp(actor))
    actor.action_used = true
    changed.emit("Warden adjusts equipment (action spent).")
    return true

func end_turn() -> bool:
    if finished:
        return false
    var checked: int = 0
    while checked <= units.size():
        if index + 1 < order.size():
            index += 1
        else:
            round += 1
            _reorder()
            index = 0
        if order.is_empty():
            return false
        var actor: V3Unit = active_unit()
        if actor != null and actor.alive():
            actor.begin_turn()
            changed.emit("%s's turn." % actor.name)
            return true
        checked += 1
    return false

func _reorder() -> void:
    var alive_units: Array[V3Unit] = []
    for unit: V3Unit in units:
        if unit.alive():
            alive_units.append(unit)
    alive_units.sort_custom(func(a: V3Unit, b: V3Unit) -> bool: return a.initiative() > b.initiative())
    order.clear()
    for unit: V3Unit in alive_units:
        order.append(unit.id)

func _check_end() -> void:
    var heroes: bool = false
    var foes: bool = false
    for unit: V3Unit in units:
        if unit.alive():
            if unit.faction == "party":
                heroes = true
            else:
                foes = true
    if not heroes or not foes:
        finished = true
        result = "VICTORY" if heroes else "DEFEAT"

func snapshot() -> Dictionary:
    var actors: Array[Dictionary] = []
    for unit: V3Unit in units:
        actors.append({"id": unit.id, "name": unit.name, "faction": unit.faction, "role": unit.role,
            "hp": unit.hp, "max_hp": max_hp(unit), "mp": unit.mp, "max_mp": unit.max_mp,
            "guarding": unit.guarding, "chilled": unit.chilled, "power": attack_power(unit), "armor": armor(unit)})
    return {"actors": actors, "order": order.duplicate(), "index": index, "round": round,
        "finished": finished, "result": result, "potions": inventory.potions,
        "equipment": inventory.equipped.duplicate(), "bag": inventory.bag.duplicate()}

func serialize() -> Dictionary:
    var actors: Array[Dictionary] = []
    for unit: V3Unit in units:
        actors.append(unit.serialize())
    return {"actors": actors,"order": order.duplicate(),"index": index,"round": round,
        "finished": finished,"result": result,"seed": str(rng.state)}

func restore(data: Dictionary) -> bool:
    var actors: Variant = data.get("actors", [])
    var saved_order: Variant = data.get("order", [])
    if not actors is Array or actors.size() != units.size() or not saved_order is Array:
        return false
    for i: int in range(units.size()):
        if not actors[i] is Dictionary or not units[i].restore(actors[i], max_hp(units[i])):
            return false
    var observed: Array[String] = []
    for key: Variant in saved_order:
        var known: bool = false
        for unit: V3Unit in units:
            if unit.id == str(key):
                known = true
                break
        if not known or observed.has(str(key)):
            return false
        observed.append(str(key))
    if observed.is_empty():
        return false
    var new_index: int = int(data.get("index", -1))
    var new_round: int = int(data.get("round", 0))
    if new_index < 0 or new_index >= observed.size() or new_round < 1 or new_round > 999999:
        return false
    order = observed
    index = new_index
    round = new_round
    finished = bool(data.get("finished", false))
    result = str(data.get("result", ""))
    if not finished and not active_unit().alive():
        return false
    rng.state = int(data.get("seed", "0"))
    changed.emit("Battle restored, including the turn queue.")
    return true
