extends SceneTree

var errors: int = 0

func _init() -> void:
    var world := V5WorldState.new()
    var bag := ModuleInventory.new()
    _check(world.player == Vector2i(2, 2), "World starts in village")
    _check(not world.passable(Vector2i(0, 0)), "World border is impassable")
    _check(not world.move(Vector2i(2, 0)), "No teleporting over tiles")
    _check(not world.finish_encounter("raider", true), "Cannot skip quest prerequisites")
    _check(world.inspect(bag)["kind"] == "none", "No scripted event on start tile")

    _travel(world, V5WorldState.ELDER, "Reach quest NPC")
    var dialogue: Dictionary = world.inspect(bag)
    _check(dialogue.get("kind") == "dialogue" and world.quest_started, "Rowan issues the quest")
    _check(world.objective_text().contains("0/2"), "Quest tracker shows first task")

    _travel(world, V5WorldState.ENCOUNTERS["boss"], "Reach sealed boss area")
    _check(world.inspect(bag)["kind"] == "dialogue", "Boss locked before patrols")
    _check(not world.finish_encounter("boss", true), "Boss reward cannot bypass patrols")

    _travel(world, V5WorldState.ENCOUNTERS["raider"], "Path to first enemy")
    _check(world.inspect(bag)["encounter"] == "raider", "Raider starts correct battle")
    _check(not world.finish_encounter("raider", false), "Defeat does not complete objective")
    _check(world.finish_encounter("raider", true), "Raider victory recorded")
    _check(not world.finish_encounter("raider", true), "No duplicate raider reward")

    _travel(world, V5WorldState.ENCOUNTERS["shaman"], "Path to second enemy")
    _check(world.inspect(bag)["encounter"] == "shaman", "Shaman starts correct battle")
    _check(world.finish_encounter("shaman", true), "Second patrol cleared")
    _check(world.objective_text().contains("Ashfang"), "Quest tracker now targets boss")

    _travel(world, V5WorldState.CHEST, "Path to treasure")
    var potions_before: int = bag.potions
    _check(world.inspect(bag)["kind"] == "treasure", "Chest opened")
    _check(bag.potions == potions_before + 2, "Treasure adds two potions")
    _check(world.inspect(bag)["kind"] == "none", "Chest cannot be looted twice")

    _travel(world, V5WorldState.ENCOUNTERS["boss"], "Return to boss")
    _check(world.inspect(bag)["encounter"] == "boss", "Boss unlocked")
    _check(world.finish_encounter("boss", true), "Boss victory recorded")
    _check(world.objective_text().contains("Return"), "Quest requires returning to Rowan")

    _travel(world, V5WorldState.ELDER, "Return to quest NPC")
    potions_before = bag.potions
    _check(world.inspect(bag)["kind"] == "dialogue", "Rowan delivers reward dialogue")
    _check(world.quest_claimed and bag.potions == potions_before + 3, "Quest awards potions once")
    world.inspect(bag)
    _check(bag.potions == potions_before + 3, "Quest reward cannot be duplicated")
    _check(world.objective_text().contains("complete"), "Quest concludes")

    var saved: Dictionary = world.to_dict()
    var other := V5WorldState.new()
    _check(other.restore(saved), "Overworld state roundtrip")
    _check(other.player == world.player and other.quest_claimed, "Position and objectives persist")
    var bad: Dictionary = saved.duplicate(true)
    bad["x"] = 0
    _check(not other.restore(bad), "Save rejects impassable position")
    _check(other.player == world.player, "Failed load does not change position")
    bad = saved.duplicate(true)
    bad["cleared"]["raider"] = false
    _check(not other.restore(bad), "Invalid boss prerequisite rejected")

    var progress := V4Progression.new()
    _check(progress.earn_victory().size() == 4, "Combat experience module retains team XP")
    var progress_copy := V4Progression.new()
    _check(progress_copy.restore(progress.to_dict()), "XP persists in world saves")

    var patrol := V3Battle.new(bag)
    patrol.create(progress_copy, "raider")
    _check(patrol.units.filter(func(a: V3Unit) -> bool: return a.faction == "enemy" and a.alive()).size() == 1,
        "Raider encounter spawns exactly one living enemy")
    _check(patrol.unit_by_id("raider").alive(), "Raider is the living patrol opponent")
    var casters := V3Battle.new(bag)
    casters.create(progress_copy, "shaman")
    _check(casters.unit_by_id("shaman").alive() and not casters.unit_by_id("raider").alive(), "Shaman patrol spawns correctly")
    var boss := V3Battle.new(bag)
    boss.create(progress_copy, "boss")
    _check(boss.units.filter(func(a: V3Unit) -> bool: return a.faction == "enemy" and a.alive()).size() == 3,
        "Boss encounter retains full enemy formation")

    var store: Dictionary = {"schema": 5, "world": world.to_dict(), "inventory": bag.to_dict(),
        "progression": progress_copy.to_dict()}
    _check(int(store["schema"]) == 5, "World save schema set")
    var loaded_bag := ModuleInventory.new()
    _check(loaded_bag.restore(store["inventory"]) and loaded_bag.potions == bag.potions,
        "Overworld potion rewards survive save/load")

    if errors == 0:
        print("V05 WORLD QUESTS AND ENCOUNTER TESTS PASSED")
    quit(1 if errors > 0 else 0)

func _travel(world: V5WorldState, target: Vector2i, label: String) -> void:
    var route: Array[Vector2i] = world.path_to(target)
    _check(not route.is_empty() or world.player == target, label)
    for step: Vector2i in route:
        _check(world.move(step - world.player), "Path step is valid")
    _check(world.player == target, "Arrived: " + label)

func _check(ok: bool, message: String) -> void:
    if ok:
        print("PASS V05: " + message)
    else:
        errors += 1
        push_error("FAIL V05: " + message)
