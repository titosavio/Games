extends CanvasLayer

@onready var label: Label = $Label

func _process(_delta):

    var last = Game.adversaries.get_last_adversary()
    if not last:
        label.text = "Nenhum rival ainda. Encosta num inimigo."
        return

    if last.is_empty():
        label.text = "Nenhum rival ainda. Encosta num inimigo."
        return

    var traits: Array = last.traits
    var mem: Array = last.memories

    label.text = "RIVAL: %s | rank %d | kills %d\nTrait: %s\nÚltima memória: %s" % [
        last.name,
        last.rank,
        last.kills,
        (traits[-1] if traits.size() > 0 else "-"),
        (mem[-1] if mem.size() > 0 else "-")
    ]
