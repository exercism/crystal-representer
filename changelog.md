# 1.3.1

- Bump Crystal to 1.12
- Ensure that the order files are loaded are the same

# 1.3.0

- Bump Crystal to 1.11
- Add description to shard.
- Added gc-dev dependencies

# 1.2.1

- Fix github pages
- Clear class data when representation is done
- Add method which allows clearing of data

# 1.2.0

## Improvements

- Improved documentation for the representer.

## new features

- Add a complete cli interface, which allows for more control over the representer.
- Add API for the representer, which allows the representer to be used as a library.
- Add Support for Crystal 1.10
- Added github documentation for the representer.

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
- Reduced the size of the representer image, from 500 mb to 30 mb.

## new features

- Add support for Crystal 1.9
- Added debug mode, which will output a more detailed information about the process (only available when using the CLI).

# 1.0.1

- Fixed crystal version used to reduce storage size

# 1.0.0

- Initial release
- Add support for Crystal 1.8