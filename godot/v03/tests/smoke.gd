extends SceneTree

var errors: int = 0

func _init() -> void:
    var bag := ModuleInventory.new()
    var sim := V3Battle.new(bag)
    sim.create()
    _check(sim.units.size() == 7, "Four heroes and three enemies")
    _check(sim.order.size() == 7, "All actors in initiative queue")
    _check(sim.active_unit().id == "kestrel", "Initiative starts with fastest unit")
    _check(sim.attack_power(sim.unit_by_id("warden")) == 8, "Equipment modifies hero attack power")
    _check(not sim.can_act("potion", "warden"), "Potion locked before regular action")
    var intelligence := V3AI.new()
    var choice: Dictionary = intelligence.choose(sim)
    _check(not choice.is_empty(), "Companion AI produces a decision")
    _check(sim.can_act(str(choice["kind"]), str(choice["target"])), "Companion decision is legal")
    _check(sim.execute("arc", "raider"), "Kestrel strikes selectable enemy")
    _check(not sim.execute("attack", "ashfang"), "Second main action blocked")
    _check(sim.end_turn(), "Initiative advances")
    _check(sim.active_unit().id == "warden", "Player receives turn")
    _check(not sim.execute("mend", "ashfang"), "Healing cannot target enemy")
    _check(not sim.execute("attack", "mira"), "Attack cannot target ally")
    _check(sim.execute("frost", "ashfang"), "Frost can target boss")
    _check(sim.unit_by_id("ashfang").chilled > 0, "Frost applies status")
    _check(sim.unit_by_id("warden").mp == 2, "Spell spends MP")
    _check(not sim.execute("attack", "ashfang"), "Cannot double action")
    var hero: V3Unit = sim.unit_by_id("warden")
    hero.hurt(17)
    var low_hp: int = hero.hp
    _check(sim.execute("potion", "warden"), "Potion unlocks after attack or spell")
    _check(hero.hp > low_hp, "Potion recovers actual HP")
    _check(bag.potions == 2, "Potion consumes exactly one item")
    _check(not sim.execute("potion", "warden"), "Bonus action is limited")
    var data: Dictionary = sim.serialize()
    var loaded := V3Battle.new(bag)
    loaded.create()
    _check(loaded.restore(data), "Battle restores with preserved turn")
    _check(loaded.active_unit().id == "warden", "Turn ownership persists")
    _check(loaded.unit_by_id("ashfang").chilled > 0, "Statuses persist")
    _check(not loaded.execute("attack", "raider"), "Consumed action stays consumed")

    var fresh_bag := ModuleInventory.new()
    _check(fresh_bag.equip("sun_charm"), "HP charm equips")
    var equip_sim := V3Battle.new(fresh_bag)
    equip_sim.create()
    _check(equip_sim.max_hp(equip_sim.unit_by_id("warden")) == 54, "Charm changes maximum HP")
    _check(equip_sim.end_turn(), "Skip initial fast ally")
    _check(equip_sim.change_gear("steel_saber", "", true), "Gear changes through authoritative combat")
    _check(equip_sim.attack_power(equip_sim.unit_by_id("warden")) == 10, "Saber updates derived power")
    _check(not equip_sim.change_gear("", "weapon", false), "Only one equipment action allowed")
    _check(fresh_bag.bag["iron_sword"] == 1, "Old sword goes to bag")
    var restored_bag := ModuleInventory.new()
    _check(restored_bag.restore(fresh_bag.to_dict()), "Equipment inventory round trip")
    _check(restored_bag.modifiers()["power"] == 4, "Saber power survives restore")
    _check(restored_bag.modifiers()["hp"] == 12, "Charm bonus survives restore")
    var all_ids: Array[String] = sim.abilities.targets("mend", sim.unit_by_id("warden"), sim.units)
    _check(all_ids.has("mira") and not all_ids.has("ashfang"), "Target rules distinguish parties")
    _check(V3Abilities.DATA.has("ember") and V3Abilities.DATA.has("frost"), "Spells registered")

    if errors == 0:
        print("V03 ALL BATTLE TESTS PASSED")
    quit(1 if errors > 0 else 0)

func _check(condition: bool, description: String) -> void:
    if condition:
        print("PASS V03: " + description)
    else:
        errors += 1
        push_error("FAIL V03: " + description)
