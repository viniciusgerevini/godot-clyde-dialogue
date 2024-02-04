# Clyde Dialogue Plugin for Godot

<p align="center"><img src="icon.png" alt=/></p>

Importer and interpreter for [Clyde Dialogue Language](https://github.com/viniciusgerevini/clyde). Completely written in GDScript. No external dependencies.

> Clyde is a language for writing game dialogues. It supports branching dialogues, translations and interfacing with your game through variables and events.

```
The Wolf:   Jimmie – lead the way, boys – get to work.
Vincent:    A "please" would be nice.
The Wolf:   Come again?
Vincent:    I said a "please" would be nice.
The Wolf:   Get it straight, Buster. I'm not here to
            say "please."I'm here to tell you what to
            do. And if self-preservation is an
            instinct you possess, you better f****n'
            do it and do it quick. I'm here to help.
            If my help's not appreciated, lotsa luck
            gentlemen.
Jules:      It ain't that way, Mr. Wolf. Your help is
            definitely appreciated.
Vincent:    I don't mean any disrespect. I just don't
            like people barkin' orders at me.
The Wolf:   If I'm curt with you, it's because time is
            a factor. I think fast, I talk fast, and I
            need you guys to act fast if you want to
            get out of this. So pretty please, with
            sugar on top, clean the f****n' car.
```

## Usage

The importer automatically imports `.clyde` files to be used with the interpreter. This improves performance, as the dialogue is parsed beforehand.

Check [USAGE.md](./USAGE.md) for how to use the interpreter.

You can find usage examples on [/addons/clyde/examples](./addons/clyde/examples)

For more about how to write dialogues using Clyde, check [clyde/LANGUAGE.md](https://github.com/viniciusgerevini/clyde/blob/master/LANGUAGE.md)

Check [sample project](https://github.com/viniciusgerevini/godot-clyde-sample)

## Instalation

Follow Godot's [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).


## Settings

Go to `Project > Project Settings > General > Dialogue`.

| Field                   | Description |
| ----------------------- | ----------- |
| Source Folder: | Default folder where the interpreter will look for `.clyde` files when just the filename is provided. Default: `res://dialogues/` |
| Id Suffix Lookup Separator: | When using id suffixes, this is the separator used in the translation keys. Default. `&`.|
| Enable Helpers: | Default: false. Enable the `Dialogue` singleton and config node. |

## Helpers

As seen in the USAGE.md, the Clyde interpreter has as simple interface giving you full control on how to display and handle your dialogues. However, there are many different ways you can go about it, which might make it daunting for new developers.

To help you quick start a project, I included a few helpers with this plugin. By enabling the helpers option in ProjectSettings, a `Dialogue` singleton and a `ClydeDialogueConfig` node will be available, allowing a quick start with no much effort.

You can find examples using these helpers on [/addons/clyde/examples](./addons/clyde/examples).

This implementation comes with a simple fixed dialogue bubble. You can adapt these helpes however you need. If you intend to change them, I recommend copying them to your project's folder so there are no conflicts when updating the plugin.
