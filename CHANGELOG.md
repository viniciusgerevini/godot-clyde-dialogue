# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

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
