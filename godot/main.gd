extends Control

var _game: ModuleCoordinator
var _round_label: Label
var _hero_label: Label
var _ally_label: Label
var _foe_label: Label
var _potions_label: Label
var _event_label: Label
var _buttons: Dictionary = {}

func _ready() -> void:
    _build_ui()
    _game = ModuleCoordinator.new()
    add_child(_game)
    _game.view_changed.connect(_render)
    _game.start_new()

func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#0c1423")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 22)
    add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)

    column.add_child(_label("IRONBOUND  •  MODULE DEMO", 29, Color("#f5ca78")))
    _round_label = _label("", 23, Color.WHITE)
    column.add_child(_round_label)

    _hero_label = _label("", 24, Color("#90d6ff"))
    _ally_label = _label("", 24, Color("#a6f3c0"))
    _foe_label = _label("", 24, Color("#ff9f9f"))
    column.add_child(_hero_label)
    column.add_child(_ally_label)
    column.add_child(_foe_label)

    column.add_child(_label("ACTION  →  BONUS  →  END TURN", 19, Color("#d9e1ee")))
    var actions := GridContainer.new()
    actions.columns = 2
    actions.add_theme_constant_override("h_separation", 12)
    actions.add_theme_constant_override("v_separation", 12)
    column.add_child(actions)
    for pair: Array in [
        ["Attack", "attack"], ["Arc Strike (2 SP)", "special"],
        ["Guard", "guard"], ["Potion (+10 HP)", "potion"],
        ["End Turn", "end"], ["Restart Battle", "restart"]
    ]:
        var button: Button = _button(pair[0])
        actions.add_child(button)
        _buttons[pair[1]] = button
        if pair[1] == "restart":
            button.pressed.connect(func() -> void: _game.start_new())
        else:
            var command: String = pair[1]
            button.pressed.connect(func() -> void: _game.command(command))

    _potions_label = _label("", 19, Color("#ffe9b3"))
    column.add_child(_potions_label)

    var storage := HBoxContainer.new()
    storage.add_theme_constant_override("separation", 12)
    column.add_child(storage)
    var save_button: Button = _button("Save")
    var load_button: Button = _button("Load")
    storage.add_child(save_button)
    storage.add_child(load_button)
    save_button.pressed.connect(func() -> void: _game.save_game())
    load_button.pressed.connect(func() -> void: _game.load_game())

    column.add_child(_label("BATTLE LOG", 20, Color("#f5ca78")))
    var scrolling := ScrollContainer.new()
    scrolling.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(scrolling)
    _event_label = _label("", 19, Color("#d6e0f0"))
    _event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrolling.add_child(_event_label)

func _label(content: String, font_size: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.add_theme_color_override("font_color", tint)
    label.add_theme_font_size_override("font_size", font_size)
    return label

func _button(text_value: String) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(0, 78)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 20)
    return button

func _render(view: Dictionary, recent_events: Array) -> void:
    _round_label.text = "Round %d   •   %s" % [view["round"], view["turn_name"]]
    _hero_label.text = _stat_line("Warden", view["hero"])
    _ally_label.text = _stat_line("Mira (AI)", view["companion"])
    _foe_label.text = _stat_line("Ashfang (AI)", view["foe"])
    _potions_label.text = "Shared potions: %d   •   SP regenerates each turn" % view["potions"]
    _buttons["attack"].disabled = not view["can_act"]
    _buttons["special"].disabled = not view["can_special"]
    _buttons["guard"].disabled = not view["can_act"]
    _buttons["potion"].disabled = not view["can_potion"]
    _buttons["end"].disabled = not view["player_turn"]
    var lines := PackedStringArray()
    for entry: Variant in recent_events:
        lines.append(str(entry))
    _event_label.text = "\n\n".join(lines)

func _stat_line(name: String, data: Dictionary) -> String:
    return "%s   HP %d/%d   SP %d%s" % [
        name, data["hp"], data["max_hp"], data["stamina"],
        "  [GUARD]" if data["guarding"] else ""
    ]
