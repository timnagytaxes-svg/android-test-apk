extends Control

var _game: ModuleCoordinator
var _arena: BattleVisuals
var _round_label: Label
var _hero_label: Label
var _ally_label: Label
var _foe_label: Label
var _help_label: Label
var _event_label: Label
var _gear_list: VBoxContainer
var _gear_summary: Label
var _buttons: Dictionary = {}
var _gear_signature: String = ""

func _ready() -> void:
    _build_ui()
    _game = ModuleCoordinator.new()
    add_child(_game)
    _game.view_changed.connect(_render)
    _game.visual_requested.connect(_arena.play_event)
    _game.start_new()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#0c1423")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 12)
    add_child(margin)
    var tabs := TabContainer.new()
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.add_theme_font_size_override("font_size", 21)
    margin.add_child(tabs)
    var battlefield := ScrollContainer.new()
    battlefield.name = "Battle"
    battlefield.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    tabs.add_child(battlefield)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 12)
    battlefield.add_child(column)
    column.add_child(_label("IRONBOUND  •  SPELLS & GEAR", 29, Color("#f5ca78")))
    _round_label = _label("", 23, Color.WHITE)
    column.add_child(_round_label)
    _arena = BattleVisuals.new()
    column.add_child(_arena)
    _hero_label = _label("", 20, Color("#95d9ff"))
    _ally_label = _label("", 20, Color("#b1ffd4"))
    _foe_label = _label("", 20, Color("#ffb1a7"))
    column.add_child(_hero_label)
    column.add_child(_ally_label)
    column.add_child(_foe_label)
    _help_label = _label("", 18, Color("#ffd88d"))
    _help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_help_label)
    var actions := GridContainer.new()
    actions.columns = 2
    actions.add_theme_constant_override("h_separation", 10)
    actions.add_theme_constant_override("v_separation", 10)
    column.add_child(actions)
    for pair: Array in [
        ["Attack", "attack"], ["Arc Strike  •  2 SP", "special"],
        ["Ember Bolt  •  1 SP", "ember"], ["Frost Shard  •  2 SP", "frost"],
        ["Mend  •  2 SP", "mend"], ["Guard", "guard"],
        ["Potion  •  +12 HP", "potion"], ["End Turn", "end"]
    ]:
        var action_id: String = str(pair[1])
        var button: Button = _button(str(pair[0]))
        actions.add_child(button)
        _buttons[action_id] = button
        button.pressed.connect(_on_action.bind(action_id))
    var storage := HBoxContainer.new()
    storage.add_theme_constant_override("separation", 10)
    column.add_child(storage)
    for pair: Array in [["Save", "save"], ["Load", "load"], ["Restart", "restart"]]:
        var button: Button = _button(str(pair[0]))
        storage.add_child(button)
        button.pressed.connect(_on_utility.bind(str(pair[1])))
    column.add_child(_label("BATTLE LOG", 22, Color("#f5ca78")))
    _event_label = _label("", 18, Color("#d6e0f0"))
    _event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_event_label)

    var equipment_page := ScrollContainer.new()
    equipment_page.name = "Equipment"
    equipment_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    tabs.add_child(equipment_page)
    var equip_column := VBoxContainer.new()
    equip_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    equip_column.add_theme_constant_override("separation", 14)
    equipment_page.add_child(equip_column)
    equip_column.add_child(_label("EQUIPMENT  •  WARDEN", 28, Color("#f5ca78")))
    var tip := _label("Equip or unequip items here. Changing gear during battle spends your regular action; end your turn to continue.", 19, Color("#c7d3e5"))
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    equip_column.add_child(tip)
    _gear_summary = _label("", 20, Color("#95d9ff"))
    equip_column.add_child(_gear_summary)
    _gear_list = VBoxContainer.new()
    _gear_list.add_theme_constant_override("separation", 12)
    equip_column.add_child(_gear_list)

func _on_action(action_id: String) -> void:
    _game.command(action_id)

func _on_utility(action_id: String) -> void:
    match action_id:
        "save": _game.save_game()
        "load": _game.load_game()
        "restart": _game.start_new()

func _on_equip(item_id: String) -> void:
    _game.change_gear(item_id, "", true)

func _on_unequip(slot_id: String) -> void:
    _game.change_gear("", slot_id, false)

func _label(content: String, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.add_theme_color_override("font_color", tint)
    label.add_theme_font_size_override("font_size", font_size)
    return label

func _button(content: String) -> Button:
    var button := Button.new()
    button.text = content
    button.custom_minimum_size = Vector2(0, 70)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 19)
    return button

func _render(view: Dictionary, recent_events: Array) -> void:
    _round_label.text = "ROUND %d     •     %s" % [view["round"], view["turn_name"]]
    _hero_label.text = _stat_line("WARDEN", view["hero"])
    _ally_label.text = _stat_line("MIRA", view["companion"])
    _foe_label.text = _stat_line("ASHFANG", view["foe"])
    _arena.sync_state(view)
    var can_act: bool = bool(view["can_act"])
    for kind: String in ["attack", "guard"]:
        _buttons[kind].disabled = not can_act
    _buttons["special"].disabled = not view["can_special"]
    _buttons["ember"].disabled = not view["can_ember"]
    _buttons["frost"].disabled = not view["can_frost"]
    _buttons["mend"].disabled = not view["can_mend"]
    _buttons["potion"].disabled = not view["can_potion"]
    _buttons["end"].disabled = not view["player_turn"]
    if view["finished"]:
        _help_label.text = "Battle ended. Restart or load your save."
    elif not view["player_turn"]:
        _help_label.text = "Enemy and companion turns resolve automatically."
    elif can_act:
        _help_label.text = "TAKE YOUR ACTION FIRST • Potion unlocks afterward if injured. Gear changes also use an action."
    else:
        _help_label.text = "BONUS WINDOW • Potion available if injured, then End Turn. Your regular action is spent."
    var lines := PackedStringArray()
    for entry: Variant in recent_events:
        lines.append(str(entry))
    _event_label.text = "\n\n".join(lines)
    _refresh_gear(view)

func _refresh_gear(view: Dictionary) -> void:
    var signature: String = JSON.stringify([view["bag"], view["equipment"], view["can_act"], view["hero"]["hp"], view["hero"]["max_hp"]])
    if signature == _gear_signature:
        return
    _gear_signature = signature
    for child: Node in _gear_list.get_children():
        child.queue_free()
    var hero: Dictionary = view["hero"]
    _gear_summary.text = "HP %d/%d   •   POW %d   •   ARM %d\nConsumables: %d potions" % [
        hero["hp"], hero["max_hp"], hero["power"], hero["armor"], view["potions"]]
    var available: bool = bool(view["can_act"])
    var equipped: Dictionary = view["equipment"]
    for slot: String in ModuleInventory.SLOTS:
        var item_id: String = str(equipped.get(slot, ""))
        var item_label: String = "Empty" if item_id.is_empty() else str(ModuleInventory.ITEMS[item_id]["name"])
        _gear_list.add_child(_label("%s: %s" % [slot.to_upper(), item_label], 22, Color("#f5ca78")))
        if not item_id.is_empty():
            var unequip_button := _button("Unequip " + item_label + "  (uses action)")
            unequip_button.disabled = not available
            _gear_list.add_child(unequip_button)
            unequip_button.pressed.connect(_on_unequip.bind(slot))
    _gear_list.add_child(_label("BACKPACK  •  AVAILABLE ITEMS", 21, Color("#b5e7fc")))
    var bag: Dictionary = view["bag"]
    for item_id: String in ModuleInventory.ITEMS.keys():
        if int(bag.get(item_id, 0)) <= 0:
            continue
        var item: Dictionary = ModuleInventory.ITEMS[item_id]
        var caption: String = "Equip %s  (%s)  +%d POW / +%d ARM / +%d HP" % [
            item["name"], item["slot"], item["power"], item["armor"], item["hp"]]
        var button := _button(caption)
        button.disabled = not available
        _gear_list.add_child(button)
        button.pressed.connect(_on_equip.bind(item_id))
    var notice := _label("Only Warden can change gear. The combat rules recalculate stats immediately; all equipment is saved.", 17, Color("#bfc9d9"))
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _gear_list.add_child(notice)

func _stat_line(name: String, data: Dictionary) -> String:
    return "%s  HP %d/%d  SP %d  POW %d  ARM %d%s" % [
        name, data["hp"], data["max_hp"], data["stamina"], data["power"], data["armor"],
        "  CHILLED" if data["chilled"] else ""
    ]
