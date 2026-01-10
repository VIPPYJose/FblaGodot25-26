extends Node

var character_id: int = 1
var character_variant: String = "male"
var dog_breed: String = "Golden_Retriever"
var pet_name: String = ""
var player_name: String = ""

func save_character(id: int, variant: String):
	character_id = id
	character_variant = variant

func save_pet(breed: String):
	dog_breed = breed

func save_pet_name(p_name: String):
	pet_name = p_name

func save_player_name(p_name: String):
	player_name = p_name
