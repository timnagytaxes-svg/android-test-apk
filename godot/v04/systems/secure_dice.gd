class_name V4SecureDice
extends RefCounted

# Equivalent in purpose to Python secrets.randbelow(): the OS-backed Godot
# cryptographic generator, with rejection sampling to avoid modulo bias.
# One 256-byte buffer covers many dice rolls; no network/Python runtime.
const WORD_SPACE: int = 4294967296
const BUFFER_BYTES: int = 256
var _crypto := Crypto.new()
var _bytes := PackedByteArray()
var _offset: int = BUFFER_BYTES

func roll(sides: int) -> int:
    assert(sides >= 1 and sides <= 65536, "Unsupported die size")
    var threshold: int = WORD_SPACE - (WORD_SPACE % sides)
    while true:
        if _offset + 4 > _bytes.size():
            _bytes = _crypto.generate_random_bytes(BUFFER_BYTES)
            _offset = 0
            if _bytes.size() != BUFFER_BYTES:
                push_error("Secure entropy source unavailable")
                return 1
        var candidate: int = int(_bytes.decode_u32(_offset))
        _offset += 4
        if candidate < threshold:
            return 1 + (candidate % sides)
    return 1

func between(low: int, high: int) -> int:
    assert(high >= low and high - low < 65536)
    return low + roll(high - low + 1) - 1

func roll_percent(chance: int) -> bool:
    return roll(100) <= clampi(chance, 0, 100)
