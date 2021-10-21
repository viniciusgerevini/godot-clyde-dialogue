# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

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
