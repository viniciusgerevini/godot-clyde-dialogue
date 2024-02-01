## Add this to the canvas used as HUD in your scene.
## Don't forget to setup the Dialogue auto-load as well.
## @tutorial: //TODO create a tutorial
extends Node

## The scene to be used as dialogue bubble
@export var _dialogue_bubble: PackedScene

## Where in the tree should dialogue bubbles be added to.
## if no Node selected this Node's parent will be used
@export var _dialogue_bubble_container: Node

## Action name from Input Map to listen to go to next content
@export var _next_content_input_action_name: String = "ui_accept"

## When in selection mode, try to stop selection
@export var _cancel_selection_input_action_name: String = "ui_cancel"

## Action name from Input Map to listen to select highlighted option
@export var _select_option_input_action_name: String = "ui_accept"

## Action name from Input Map to listen to go to next option
@export var _next_option_input_action_name: String = "ui_down"

## Action name from Input Map to listen to go to previous option
@export var _previous_option_input_action_name: String = "ui_up"


func _ready():
	Dialogue.config = self


func load_data(dialogue_path: String, block_name: String) -> Dictionary:
	return _load_dialogue_data(dialogue_path, block_name)


func persist_data(dialogue_path: String, block_name: String, dialogue_data: Dictionary) -> void:
	_persist_dialogue_data(dialogue_path, block_name, dialogue_data)


func get_config() -> Dictionary:
	return {
		"bubble": _dialogue_bubble,
		"bubble_container": _dialogue_bubble_container if _dialogue_bubble_container != null else self.get_parent(),
		"input": {
			"next_content": _next_content_input_action_name,
			"select_option": _select_option_input_action_name,
			"cancel_selection": _cancel_selection_input_action_name,
			"next_option": _next_option_input_action_name,
			"previous_option": _previous_option_input_action_name,
		}
	}


## Override this method. Should return any existing persistence object for the dialogue.
## Return empty if first run.
func _load_dialogue_data(dialogue_path: String, block_name: String) -> Dictionary:
	return {}


## Override this method. Called after a dialogue is finished. Should be used for persisting
## dialogue data.
func _persist_dialogue_data(dialogue_path: String, block_name: String, dialogue_data: Dictionary) -> void:
	pass
