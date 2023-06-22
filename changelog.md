# 1.1.0

## Bug fixes

- Fixed an issue which caused so that methods using `blocks` where not reorganized correctly.
  Causing other methods being marked to have a block while not having one.
- Fixed an issue when `getter` and `property` were given a symbol as name, so were they not represented correctly.
- Fixed an issue where std types were picked up by alias and thereby categorized as a user deffined type.
- Fixed an issue which caused method overloading to store multiple methods with the same name.
- Fixed an issue where nested methods became unnested.

## Improvements

- Reduced the size of the source files by using macros and more efficient code.

## new features

- Add support for Crystal 1.9

# 1.0.1

- Fixed crystal version used to reduce storage size

# 1.0.0

- Initial release
- Add support for Crystal 1.8