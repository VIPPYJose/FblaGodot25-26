# COMMIT: Achievements and Catch Minigame Update
extends Node

## Autoload that stores the player's character customization and name.
## Persists only in memory for the current session (across scene changes).
## Not saved to disk, so choices are reset when the game is closed.

const DEFAULT_OPTION := 1
const MIN_OPTION := 1
const MAX_OPTION := 5

var body: int = DEFAULT_OPTION
var hairstyle: int = DEFAULT_OPTION
var outfit: int = DEFAULT_OPTION
var eyes: int = DEFAULT_OPTION
var accessory: int = DEFAULT_OPTION
var player_name: String = ""


## Returns the option index (1-5) for the given category.
func get_option(category: StringName) -> int:
	match category:
		&"Body": return body
		&"Hairstyle": return hairstyle
		&"Outfit": return outfit
		&"Eyes": return eyes
		&"Accessory": return accessory
	return DEFAULT_OPTION


## Sets the option (1-5) for the given category (session only, not saved to disk).
func set_option(category: StringName, value: int) -> void:
	var v := clampi(value, MIN_OPTION, MAX_OPTION)
	match category:
		&"Body": body = v
		&"Hairstyle": hairstyle = v
		&"Outfit": outfit = v
		&"Eyes": eyes = v
		&"Accessory": accessory = v


## Returns animation name for a category (e.g. "Option1" .. "Option5").
func get_animation_name(category: StringName) -> String:
	return "Option%d" % get_option(category)


## Maps Option1-5 to resource paths for character_components_animations.
## Returns the path to the SpriteFrames .tres for the selected option in each category.
const COMPONENT_PATHS := {
	&"Body": [
		"res://resources/character_components_animations/body/Body_01.tres",
		"res://resources/character_components_animations/body/Body_02.tres",
		"res://resources/character_components_animations/body/Body_03.tres",
		"res://resources/character_components_animations/body/Body_04.tres",
		"res://resources/character_components_animations/body/Body_07.tres",
	],
	&"Hairstyle": [
		"res://resources/character_components_animations/hairstyle/Hairstyle_01_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_02_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_05_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_06_04.tres",
		"res://resources/character_components_animations/hairstyle/Hairstyle_19_04.tres",
	],
	&"Eyes": [
		"res://resources/character_components_animations/eyes/Eyes_01.tres",
		"res://resources/character_components_animations/eyes/Eyes_03.tres",
		"res://resources/character_components_animations/eyes/Eyes_04.tres",
		"res://resources/character_components_animations/eyes/Eyes_05.tres",
		"res://resources/character_components_animations/eyes/Eyes_06.tres",
	],
	&"Outfit": [
		"res://resources/character_components_animations/outfit/Outfit_01_03.tres",
		"res://resources/character_components_animations/outfit/Outfit_02_01.tres",
		"res://resources/character_components_animations/outfit/Outfit_04_02.tres",
		"res://resources/character_components_animations/outfit/Outfit_07_02.tres",
		"res://resources/character_components_animations/outfit/Outfit_10_04.tres",
	],
	&"Accessory": [
		"res://resources/character_components_animations/accessory/Accessory_03_Backpack_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_04_Snapback_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_04_Snapback_04.tres",
		"res://resources/character_components_animations/accessory/Accessory_11_Beanie_01.tres",
		"res://resources/character_components_animations/accessory/Accessory_15_Glasses_01.tres",
	],
}


func get_sprite_frames_path(category: StringName, option: int) -> String:
	var paths: Array = COMPONENT_PATHS.get(category, [])
	var idx := clampi(option, MIN_OPTION, MAX_OPTION) - 1
	return paths[idx] if idx < paths.size() else paths[0]


## Returns a dictionary of all options for use when spawning the player in-game.
## Keys: body, hairstyle, outfit, eyes, accessory (each 1-5), player_name (String).
func get_all() -> Dictionary:
	return {
		"body": body,
		"hairstyle": hairstyle,
		"outfit": outfit,
		"eyes": eyes,
		"accessory": accessory,
		"player_name": player_name,
	}


func set_player_name(new_name: String) -> void:
	player_name = new_name
