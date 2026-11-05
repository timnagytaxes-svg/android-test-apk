extends SceneTree

var _failures: int = 0

func _init() -> void:
    var bag := ModuleInventory.new()
    var rules := ModuleAbilityRules.new()
    var combat := ModuleCombat.new(rules, bag)
    combat.start_battle()

    _check(combat.current_actor().id == "hero", "Player starts by initiative")
    _check(not combat.execute("potion"), "Bonus blocked until action")
    _check(combat.execute("special", "foe"), "Special attack executes")
    _check(combat.actor_by_id("hero").stamina == 1, "Special spends stamina")
    _check(not combat.execute("attack", "foe"), "Second action blocked")
    _check(combat.advance_turn(), "Next initiative turn")
    _check(combat.current_actor().id == "foe", "Enemy turn follows")
    var ai := ModuleTacticalAI.new()
    var decision: Dictionary = ai.choose(combat)
    _check(decision.get("target") == "hero", "Enemy AI chooses player")
    _check(combat.execute("attack", "hero"), "Enemy attack works")
    _check(combat.advance_turn(), "Companion turn")
    _check(combat.current_actor().id == "companion", "Companion acts independently")
    decision = ai.choose(combat)
    _check(combat.execute(str(decision["kind"]), str(decision["target"])), "Companion action succeeds")
    _check(combat.advance_turn(), "Next round")
    _check(combat.current_actor().id == "hero", "Player regains control")
    _check(combat.execute("attack", "foe"), "Player attacks next round")
    var hp_before: int = combat.actor_by_id("hero").hp
    _check(combat.execute("potion"), "Potion allowed after action")
    _check(combat.actor_by_id("hero").hp > hp_before, "Potion actually heals")
    _check(bag.potions == 1, "Inventory was consumed")
    _check(not combat.execute("potion"), "Only one bonus action per turn")

    var store := ModuleSaveStore.new()
    var payload: Dictionary = {"schema": 1, "combat": combat.to_dict(), "inventory": bag.to_dict()}
    _check(store.write(payload), "Save written")
    var loaded: Dictionary = store.read()
    _check(int(loaded.get("schema", 0)) == 1, "Save read")
    var restored_bag := ModuleInventory.new()
    _check(restored_bag.restore(loaded["inventory"]), "Inventory restored")
    var restored := ModuleCombat.new(rules, restored_bag)
    _check(restored.restore(loaded["combat"]), "Combat restored")
    _check(restored.actor_by_id("hero").hp == combat.actor_by_id("hero").hp, "Health preserved")
    _check(restored.current_actor().id == "hero", "Turn preserved")
    _check(not restored.execute("attack", "foe"), "Action economy preserved after loading")
    if _failures == 0:
        print("ALL MODULE TESTS PASSED")
    quit(1 if _failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
    if condition:
        print("PASS: " + description)
    else:
        _failures += 1
        push_error("FAIL: " + description)
