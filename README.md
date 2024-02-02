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

_This branch has the source code for Godot 4. For Godot 3 check the [godot_3](https://github.com/viniciusgerevini/godot-clyde-dialogue/tree/godot_3) branch._

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
