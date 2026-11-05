extends SceneTree

var _failures: int = 0

func _init() -> void:
    var bag := ModuleInventory.new()
    var rules := ModuleAbilityRules.new()
    var combat := ModuleCombat.new(rules, bag)
    combat.start_battle()
    _check(combat.current_actor().id == "hero", "Initiative starts with player")
    _check(not combat.execute("potion"), "Potion is bonus action AFTER regular action")
    _check(bag.equipped["weapon"] == "iron_sword", "Initial weapon equipped")
    _check(combat.power_for(combat.actor_by_id("hero")) == 8, "Equipped weapon increases power")

    _check(combat.change_gear("steel_saber", "", true), "Equip item during player action")
    _check(combat.power_for(combat.actor_by_id("hero")) == 10, "New weapon changes derived attack")
    _check(bag.bag["iron_sword"] == 1, "Old weapon returned to bag")
    _check(not combat.execute("attack", "foe"), "Equipment change consumes regular action")
    _check(combat.advance_turn(), "Advance to enemy")
    var ai := ModuleTacticalAI.new()
    var plan: Dictionary = ai.choose(combat)
    _check(plan.get("target") == "hero", "Enemy AI picks player")
    _check(combat.execute(str(plan["kind"]), str(plan["target"])), "Enemy attacks")
    _check(combat.advance_turn(), "Advance to ally")
    plan = ai.choose(combat)
    _check(combat.execute(str(plan["kind"]), str(plan["target"])), "Ally AI attacks")
    _check(combat.advance_turn(), "Return to player")
    _check(combat.execute("frost", "foe"), "Frost spell works")
    _check(combat.actor_by_id("foe").chilled, "Frost applies chill")
    _check(combat.actor_by_id("hero").stamina == 1, "Frost spends SP")
    _check(not combat.execute("ember", "foe"), "One regular action per turn")
    var previous_hp: int = combat.actor_by_id("hero").hp
    _check(combat.execute("potion"), "Potion unlocks after action")
    _check(combat.actor_by_id("hero").hp > previous_hp, "Potion restores HP")
    _check(bag.potions == 2, "Potion consumed")
    _check(not combat.execute("potion"), "Second bonus potion denied")

    var payload: Dictionary = {"schema": 2, "combat": combat.to_dict(), "inventory": bag.to_dict()}
    var store := ModuleSaveStore.new()
    _check(store.write(payload), "Save persists")
    var loaded: Dictionary = store.read()
    var restored_bag := ModuleInventory.new()
    _check(restored_bag.restore(loaded["inventory"]), "Equipment restored")
    var restored := ModuleCombat.new(rules, restored_bag)
    _check(restored.restore(loaded["combat"]), "Battle restored")
    _check(restored.power_for(restored.actor_by_id("hero")) == 10, "Equipped stat retained")
    _check(restored.actor_by_id("foe").chilled, "Chill status retained")
    _check(not restored.execute("ember", "foe"), "Action economy retained")
    _check(not restored_bag.equip("iron_sword") == false or restored_bag.bag["steel_saber"] == 1, "Gear swapping remains functional")

    var bag2 := ModuleInventory.new()
    _check(bag2.equip("sun_charm"), "Equip HP charm")
    var heal_combat := ModuleCombat.new(rules, bag2)
    heal_combat.start_battle()
    _check(heal_combat.max_hp_for(heal_combat.actor_by_id("hero")) == 48, "Charm raises max HP")
    _check(heal_combat.execute("attack", "foe"), "Attack uses regular action")
    _check(not heal_combat.execute("mend", "hero"), "Cannot cast heal after action")
    _check(heal_combat.advance_turn(), "Enemy turn")
    _check(heal_combat.execute("attack", "hero"), "Enemy damages player")
    _check(heal_combat.advance_turn(), "Ally turn")
    _check(heal_combat.execute("mend", "hero"), "Ally can cast heal on player")
    _check(heal_combat.advance_turn(), "New round")
    _check(heal_combat.execute("ember", "foe"), "Ember spell works")

    if _failures == 0:
        print("ALL MODULE TESTS PASSED")
    quit(1 if _failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: " + description)
    else:
        _failures += 1
        push_error("FAIL: " + description)
