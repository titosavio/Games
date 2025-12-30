extends Node


var adversaries: AdversarySystem

func _ready():
    randomize()
    adversaries = AdversarySystem.new()
