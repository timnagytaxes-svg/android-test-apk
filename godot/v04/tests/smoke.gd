extends SceneTree

var failures: int = 0

func _init() -> void:
    var dice := V4SecureDice.new()
    var observed: Dictionary = {}
    for i: int in range(100):
        var roll: int = dice.roll(20)
        _check(roll >= 1 and roll <= 20, "Cryptographic d20 stays in range")
        observed[roll] = true
    _check(observed.size() > 1, "Random draws have variation")
    _check(dice.roll_percent(0) == false, "Zero chance never succeeds")
    _check(dice.roll_percent(100), "Full chance always succeeds")
    _check(dice.between(-2, 2) >= -2, "Signed ranges supported")

    var progress := V4Progression.new()
    _check(progress.hero_class == "vanguard", "Starting class Vanguard")
    var bag := ModuleInventory.new()
    var battle := V3Battle.new(bag)
    battle.create(progress)
    var hero: V3Unit = battle.unit_by_id("warden")
    _check(hero.health == 47 and hero.power == 8 and hero.defense == 4, "Vanguard grants class stats")
    _check(not battle.can_act("cleave", "raider"), "Class skill locked at level one")
    _check(progress.earn_victory().size() == 4, "Party earns experience together")
    _check(progress.victories == 1, "Victory counted exactly once")
    _check(progress.heroes["warden"]["level"] == 2, "XP crosses level-up threshold")
    _check(progress.heroes["warden"]["xp"] == 10, "Excess XP carries over")
    _check(progress.change_class("spellblade"), "Class switching accepted")
    _check(not progress.change_class("nonexistent"), "Invalid class rejected")

    var next := V3Battle.new(bag)
    next.create(progress)
    hero = next.unit_by_id("warden")
    _check(hero.level == 2 and hero.role == "spellblade", "Class and level applied to new encounter")
    _check(hero.max_mp >= 7 and hero.power >= 8, "Spellblade stats and growth applied")
    _check(next.end_turn(), "Advance to Warden")
    _check(next.active_unit().id == "warden", "Warden receives turn")
    _check(next.can_act("surge", "raider"), "Spellblade level-two skill unlocked")
    _check(not next.can_act("cleave", "raider"), "Vanguard skill unavailable to spellblade")
    var enemy: V3Unit = next.unit_by_id("raider")
    var enemy_hp: int = enemy.hp
    _check(next.execute("surge", "raider"), "Surge deals randomized damage")
    _check(enemy.hp < enemy_hp, "Damage actually applied")
    _check(not next.can_act("attack", "raider"), "No double action after surge")
    _check(next.serialize().has("seed") == false, "Secure RNG state is not saved")

    var restored_progress := V4Progression.new()
    _check(restored_progress.restore(progress.to_dict()), "Progression can be restored")
    _check(restored_progress.hero_class == "spellblade", "Class survives persistence")
    _check(restored_progress.heroes["warden"]["level"] == 2, "Level survives persistence")
    var preserved := V3Battle.new(bag)
    preserved.create(restored_progress)
    _check(preserved.restore(next.serialize()), "Battle loads after progression")
    _check(preserved.unit_by_id("warden").level == 2, "Level remains on loaded actor")

    var coordinator := V3Coordinator.new()
    coordinator.new_encounter()
    _check(coordinator.battle.end_turn(), "Coordinator's player turn follows fast ally")
    for e: String in ["ashfang", "shaman"]:
        coordinator.battle.unit_by_id(e).hp = 0
    coordinator.battle.unit_by_id("raider").hp = 1
    _check(coordinator.battle.execute("attack", "raider"), "Winning blow resolves")
    _check(coordinator.battle.finished, "Encounter recognizes victory")
    _check(coordinator.progression.victories == 1, "Coordinator awards victory XP")
    _check(coordinator.save_game(), "Progression and battle save")
    coordinator.new_encounter()
    _check(coordinator.battle.unit_by_id("warden").level == 2, "Level carries into next encounter")
    _check(coordinator.load_game(), "Saved progress and gear load")
    _check(coordinator.progression.victories == 1, "Victory rewards cannot double on load")

    if failures == 0:
        print("V04 ALL PROGRESSION AND SECURE DICE TESTS PASSED")
    quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
    if not condition:
        failures += 1
        push_error("FAIL V04: " + description)
    else:
        print("PASS V04: " + description)
