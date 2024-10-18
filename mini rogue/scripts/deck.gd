extends Node

var cards_rooms = {
	"event": "res://scenes/cards/card_event.tscn",
	"merchant": "res://scenes/cards/card_merchant.tscn",
	"monster": "res://scenes/cards/card_monster.tscn",
	"resting": "res://scenes/cards/card_resting.tscn",
	"trap": "res://scenes/cards/card_trap.tscn",
	"treasure": "res://scenes/cards/card_treasure.tscn",
}
var cards_boss = "res://scenes/cards/card_boss_monster.tscn"

func create_deck() -> Array:
	var deck = []
	for card_scene in cards_rooms.values():
		var card = load(card_scene).instantiate()
		
		deck.append(card)
	return deck

func shuffle_cards(deck: Array) -> void:
	deck.shuffle()
	
func place_cards(deck: Array, is_last_floor: bool=false) -> Array:
	var ordered_deck = []
	shuffle_cards(deck)
	for card in deck:
		ordered_deck.append(card)
	if is_last_floor:
		var boss_card = load(cards_boss).instantiate()  # Instanciar a carta do boss
		ordered_deck.append(boss_card)
	
	return ordered_deck

func resize_card(card: Control, proportion: float = 0.3, viewport: Viewport = null) -> void:
	if not viewport:
		viewport = get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var card_sprite = card.get_node("Sprite2D")
		card_sprite.scale = Vector2(proportion, proportion) * (viewport_size.x / card_sprite.texture.get_size().x)
		
