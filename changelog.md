# 1.1.0

## Bug fixes

- Fixed an issue which caused so that methods using `blocks` where not reorganized correctly.
  Causing other methods being marked to have a block while not having one.
- Fixed an issue where std types were picked up by alias and thereby categorized as a user defined type.
- Fixed an issue which caused method overloading to store multiple methods with the same name.
- Fixed an issue where nested methods became unnested.
- Fixed an issue causing other items being marked with a visibility modifier other than a method, to be included in the sorting of methods.
  This caused an index out of bounds error, which made so those solutions were not represented.

## Improvements

- Reduced the size of the source files by using macros and more efficient code.
- The representer will now output the error message if an error occurs.
- Added so when `getter` and `property` are given a symbol as argument, so will they now be represented

## new features

- Add support for Crystal 1.9
- Added debug mode, which will output a more detailed information about the process (only available when using the CLI).

# 1.0.1

- Fixed crystal version used to reduce storage size

# 1.0.0

- Initial release
- Add support for Crystal 1.8