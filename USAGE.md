# Clyde Interpreter Usage

For details about Clyde and how to write dialogues, check [Clyde/LANGUAGE.md](https://github.com/viniciusgerevini/clyde/blob/master/LANGUAGE.md)

## Interpreter's interface

This plugin exposes the interpreter as `ClydeDialogue`.

This is `ClydeDialogue`'s interface:

```gdscript
extends Node

signal variable_changed(variable_name, value, previous_vale)
signal event_triggered(event_name)

# Folder where the interpreter should look for dialogue files
# in case just the name is provided.
var dialogue_folder = 'res://dialogues/'


# Load dialogue file
# file_name: path to the dialogue file.
#            i.e 'my_dialogue', 'res://my_dialogue.clyde', res://my_dialogue.json
# block: block name to run. This allows keeping
#        multiple dialogues in the same file.
func load_dialogue(file_name, block = null)


# Start or restart dialogue. Variables are not reset.
func start(block_name = null)


# Get next dialogue content.
# The content may be a line, options or null.
# If null, it means the dialogue reached an end.
func get_content():


# Choose one of the available options.
# option_index: index starting in 0.
func choose(option_index)


# Set variable to be used in the dialogue
# name: variable name
# value: variable value
func set_variable(name, value)


# Get current value of a variable inside the dialogue.
# name: variable name
func get_variable(name)


# Return all variables and internal variables. Useful for persisting the dialogue's internal
# data, such as options already choosen and random variations states.
func get_data()


# Load internal data
func load_data(data)


# Clear all internal data
func clear_data()

```

### Creating an object

You need to instantiate a `ClydeDialogue` object.

``` gdscript
var dialogue = ClydeDialogue.new()
```


### Loading files

The interpreter supports loading parsed JSON files, as well as `.clyde` files imported in the project.

When only the file name is provided, the interpreter will look into the default folder defined on `dialogue.dialogue_folder`.

``` gdscript
dialogue.load_dialogue('my_dialogue')
# or
dialogue.load_dialogue('res://dialogues/my_dialogue.clyde')
# or
dialogue.load_dialogue('res://dialogues/my_dialogue.json')
```

As you can have more than one dialogue defined in a file through blocks, you can provide the block name to be used.
``` gdscript
dialogue.load_dialogue('level_001', 'first_dialogue')
```

### Starting / Restarting a dialogue

You can use `dialogue.start()` at any time to restart a dialogue or start a different block.

``` gdscript
# starts default dialogue
dialogue.start()

# starts a different block
dialogue.start('block_name')
```
Restarting a dialogue won't reset the variables already set.


### Getting next content

You should use `dialogue.get_content()` to get the next available content.

This method may return one of the following values:

#### Line

A dialogue line (`Dictionary`).

```gdscript
{
    "type": "line",
    "text": "Ahoy!",
    "speaker": "Captain", # optional
    "id": "123", # optional
    "tags": ["happy"] # optional
}
```

#### Options

Options list with options/topics the player may choose from (`Dictionary`).

```gdscript
{
    "type": "options",
    "name": "What do you want to talk about?", # optional
    "speaker": "NPC", # optional
    "options": [
      {
        "label": "option display text",
        "speaker": "NPC", # optional
        "id": "abc", # optional
        "tags": [ "some_tag" ], # optional
      },
      ...
    ]
}
```

#### Null

If `dialogue.get_content()` returns `Null`, it means the dialogue reached an end.


### Listening to variable changes

You can listen to variable changes by observing the `variable_changed` signal.

``` gdscript
  # ...

  dialogue.connect('variable_changed', self, '_on_variable_changed')


func _on_variable_changed(variable_name, value, previous_vale):
    if variable_name == 'hp' and value < previous_value:
        print('damage taken')

```

### Listening to events

You can listen to events triggered by the dialogue by observing the `event_triggered` signal.

``` gdscript
  # ...

  dialogue.connect('event_triggered', self, '_on_event_triggered')


func _on_event_triggered(event_name):
    if event_name == 'self_destruction_activated':
        _shake_screen()
        _play_explosion()

```

### Data persistence

To be able to use variations, single-use options and internal variables properly, you need to persist the dialogue data after each execution.

If you create a new `ClydeDialogue` without doing it so, the interpreter will show the dialogue as if it was the first time it was run.

You can use `dialogue.get_data()` to retrieve all internal data, and then later use `dialogue.load_data(data)` to re-populate the internal memory.


Here is a simplified implementation:

``` gdscript
var _dialogue_filename = 'first_dialogue'
var _dialogue

func _ready():
    _dialogue = ClydeDialogue.new()
    _dialogue.load_dialogue(_dialogue_filename)
    _dialogue.load_data(persistence.dialogues[_dialogue_filename]) # load data


func _get_next_content():
    var content = _dialogue.get_content()

    # ...

    if content == null:
        _dialogue_ended()


func _dialogue_ended():
    persistence.dialogues[_dialogue_filename] = _dialogue.get_data() # retrieve data for persistence

```

The example above assumes there is a global object called `persistence`, which is persisted every time the game is saved.

When starting a new dialogue execution, the internal data is loaded from the `persistence` object. When the dialogue ends, we update said object with the new values.

Note that the data is saved in in the dictionary under the dialogue filename key. The internal data should be used only in the same dialogue it was extracted from.

You should not change this object manually. If you want't to change a variable used in the previous execution, you should use `dialogue.set_variable(name, value)`.

``` gdscript
    # ...
    _dialogue = ClydeDialogue.new()
    _dialogue.load_dialogue(_dialogue_filename)
    _dialogue.load_data(persistence.dialogues[_dialogue_filename])

    _dialogue.set_variable("health", character.health)
```


### Translations / Localisation

Godot already comes with a [localisation solution](https://docs.godotengine.org/en/stable/getting_started/workflow/assets/importing_translations.html#doc-importing-translations) built-in.

The interpreter leverages this solution to translate its dialogues. Any dialogue line which contains an id defined will be translated to the current locale if a translation is available.

In case there is no translation for the id provided, the interpreter will return the default line.


## Dialogue folder and organisation

By default, the interpreter will look for files under `res://dialogues/`. In case you want to specify a different default folder, you need to change the `dialogue_folder` variable.

```gdscript
var dialogue = ClydeDialogue.new()
dialogue.dialogue_folder = "res://samples"

dialogue.load_dialogue("banana") # this line will load res://samples/banana.clyde

```

Alternatively, you can use the full path when loading dialogues:

```gdscript
var dialogue = ClydeDialogue.new()

dialogue.load_dialogue("res://samples/banana.clyde")

```

## Examples

You can find usage examples on [/example/](./example/) folder.


