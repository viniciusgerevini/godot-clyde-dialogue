# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## Unreleased

### Breaking changes

- Dialogues now return an object when ended. This impacts how you determined if the dialogue has ended.
- Changed identifier for blocks when persisting so changing block order does not impact already saved files. This will impact variations and single use options on all existing save files.
- Variation standalone `shuffle` option does simple random and has no guarantee every item will be returned.

### Added

- Assignment initializer operator `?=`. It only assigns if variable was not set before.
- `has_block` method helper to check if block exists before starting dialogue. (@HexagonNico)
- Editor main panel. Edit Clyde files directly in Godot.
- Dialogue player. Execute and debug dialogues directly in Godot.
- Id generator tool. Add random ids to lines without ids.
- CSV exporter tool. Generate a translation CSV for the dialogue.
- Resource loader and saver to simplify file usage.
- External variable support. You can set variables that are not included in the persistence object.
- Implemented helpers: Dialogue config, singleton and fixed and floating dialogue bubbles.

### Changed

- Increment assigment now have default values. i.e. If you run `set a += 1` when `a` is not set, it will be set to 1. Before it would break because value was null.
    - As `+` is also used for strings, this `set a += "abc"` also works.
- Return end object (`{ "type": "end" }`) instead of null on dialogue end.
- Make variation `shuffle` option be really random. There is no guarantee all items will be executed.
- The importer now saves a ClydeDialogueFile resource instead of PackedDataContainer.
- Improve dialogue examples.

### Fixed

- Use correct `fmod` for `a %=` operations.
- Fixed crash when exiting editor started via command line (@Rubonnek).
- Changing block order in file does not impact persisted options and variations anymore.

### Thanks

- Thanks to @Rubonnek for finding and fixing the exit crash.
- Thanks to @ThePat02 for updating the doc comments to be Godot 4's doc comments.
- Thanks to @HexagonNico for implementing the `has_block` helper.

## 3.2.1 (2023-09-07)

### Fixed

- Added an override to the importer priority as it seems this was breaking the importer in some machines.

### Thanks

Thanks to @RogerRandomDev for reporting and fixing this issue.

## 3.2.0 (2022-08-25)

### Added

- Implemented support for id suffixes. `dialogue line $id&variable_1&variable_2`.
- Id Suffix Lookup Separator project setttings. `Project > Project Settings > General > Dialogue > Id Suffix Lookup Separator`.

### Fixed
- Remove prop check warning in Output console

## 3.1.0

### Added

- Dialogue source folder project setttings. `Project > Project Settings > General > Dialogue > Source Folder`.
  When only the file name is provided, the interpreter will look for files in the folder set on `dialogue/source_folder`.

### Fixed

- Standalone `{set a}` would pass parser, but break on interpreter. Now, this is equivalent to `{ set a = true }`.
- Fix inconsistencies with logic blocks in tab indented files.

## 3.0.0 (2021-11-22)

### Breaking Changes

- Options won´t print first line as before.
- Brackets (`[]`) used for display-only options are not supported anymore.
- To reproduce previous behaviour, options should contain the new display-option symbol (`=`)

Here is a sample on how to fix your dialogues for this new version:

Old way:
```
+ This will be displayed
* This will be displayed
> This will be displayed

+ [This won't be displayed]
  some text...
* [This won't be displayed]
  some text...
> [This won't be displayed]
  some text...
```
New way:
```
+= This will be displayed
*= This will be displayed
>= This will be displayed

+ This won't be displayed
  some text...
* This won't be displayed
  some text...
> This won't be displayed
  some text...
```

### Changed

- Changed options default behaviour. (check breaking changes)

### Thanks

Thanks to @jcandres and @verillious for suggestions and input.

## 2.0.1 (2021-11-04)

### Fixed

- Used Options and Variations were not loaded correctly after loading previously stringified internal memory.

There is a known related issue with variables that will be fixed in the next major version. Variable names should be string,
but currently their type is not validated. If you define a variable with a number as name, you will only be able to recover it
as string. i.e `dialogue.set_variable(1, "blah")`, after persistence will only be available through `dialogue.get_variable("1")`.

### Thanks

Thanks to @jcandres for spotting this issue.

## 2.0.0 (2021-10-21)

### Breaking Changes

Dialogues starting with single quotes will escape especial characters.

For example:
```
'This is a #quoted text'
```
Would previously return:
```
TEXT: 'this is a
TAG:  quoted
TEXT: text'
```
Now it returns:
```
TEXT: This is a #quoted text
```

### Changed

- support single quotes for logic block string literals and escaping dialogues.
    - `{ set string_literal = 'valid string' }`
    - `'This is a valid escaped dialogue line # $ '`

### Thanks

Thanks to @verillious for suggesting and implementing these changes.

## 1.0.2 (2021-06-04)

### Added

- Condition blocks before line can use the "when" keyword.

### Fixed

- Diverts support conditional blocks before and after line

## 1.0.1 (2021-05-09)

### Fixed

- Extend scripts from `Reference` instead of `Node` to prevent memory leaks.

### Thanks

Thanks to Enes Yesilyurt (@Tols-Toy) for spotting the memory leak and for suggesting a fix for it.

## 1.0.0 (2021-02-18)

Initial release

### Added

- Importer
- Interpreter
