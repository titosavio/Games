extends Node2D

const deck_script = preload("res://scripts/deck.gd")
const Dice = preload("res://scripts/dice.gd") 

@onready var cards_container = $CardContainer

@onready var dice = Dice.new()

var is_last_floor = false
var cards = []

func _ready() -> void:
	var deck_code = deck_script.new()
	var deck = deck_code.create_deck()
	cards = deck_code.place_cards(deck, is_last_floor)
	for card in cards:
		deck_code.resize_card(card, 0.2, get_viewport())
	
	show_cards(cards)
	
func show_cards(cards_to_show: Array) -> void:
	var counter = 0
	var viewport_size = get_viewport().get_visible_rect().size
	for card in cards_to_show:
		cards_container.add_child(card)
		var card_size = card.get_node("Sprite2D").texture.get_size()
		card.position = Vector2(-viewport_size.x/3 + counter * viewport_size.x / (card_size[0]*0.05), viewport_size.y/2-card_size[1]/2)
		counter += 1
	print("Cards added to game: ", str(counter))
		
