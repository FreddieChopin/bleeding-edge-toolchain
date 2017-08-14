Change Log
==========

All notable changes to this project will be documented in this file.

[Unreleased](https://github.com/FreddieChopin/bleeding-edge-toolchain/compare/170503...HEAD)
--------------------------------------------------------------------------------------------

- Updated binutils to version 2.29.

[170503](https://github.com/FreddieChopin/bleeding-edge-toolchain/compare/170314...170503) - 2017-05-03
-------------------------------------------------------------------------------------------------------

### Changed

- Updated gcc to version 7.1.0.
- Updated newlib to version 2.5.0.20170421.
- Updated isl to version 0.18.
- Download isl from project's website, as gcc's ftp doesn't have the most recent version.
- Explicitly disabled guile support in gdb, as recent versions of these projects are incompatible (see
[bug 21104](https://sourceware.org/bugzilla/show_bug.cgi?id=21104)).

### Fixed

- Fixed Windows builds of GCC snapshots, which failed because GCC's version (e.g. *7.0.1*) doesn't match snapshot
version (e.g. *7-20170409*).

### Removed

- Big-endian version of multilib for *ARMv7-R* targets, as now multilib configuration is part of the mainline GCC.

[170314](https://github.com/FreddieChopin/bleeding-edge-toolchain/compare/170107...170314) - 2017-03-14
-------------------------------------------------------------------------------------------------------

### Added

- `--keep-build-folders` option, which will disable removal of unneeded build folders.
- `--skip-nano-libraries` option, which will skip building of "nano" libraries, making the build much shorter.

### Changed

- Build folders are deleted as soon as they are not needed anymore.
- Download isl from gcc's ftp, as it is more reliable.
- Updated newlib to version 2.5.0.20170228.
- Updated binutils to version 2.28.
- Updated gdb to version 7.12.1.
- Updated libiconv to version 1.15.
- Updated zlib to version 1.2.11.
- Allow overriding `XZ_OPT` when calling the script.
- Both newlib and newlib-nano are built with the new `--enable-newlib-retargetable-locking` option.

### Fixed

- Fixed missing `newlib.h` when using `nano.specs`.
- Fixed download location for zlib.

[170107](https://github.com/FreddieChopin/bleeding-edge-toolchain/compare/161029...170107) - 2017-01-07
-------------------------------------------------------------------------------------------------------

### Added

- Support for "nano" variant of libraries.
- Big-endian version of multilib for *ARMv7-R* targets (by Jiri Dobry).
- Re-enabled PDF documentation for all components.

### Changed

- More detailed info about requirements to build the toolchain in README.md.
- Updated gcc to version 6.3.0.
- Updated newlib to version 2.5.0.
- Updated gmp to version 6.1.2.
- Updated isl to version 0.16.1.
- Updated python to version 2.7.13.
- Updated zlib to version 1.2.10.
- Download zlib from sourceforge, as zlib's official website seems to host only the most recent version.

### Fixed

- Removed duplicate content in gcc multilib patch (by Jiri Dobry).
- Fixed brackets in gcc multilib patch, which restores libraries for *ARMv7-R* targets (by Jiri Dobry).
- Fixed missing libstdc++ "pretty printers" in Windows packages.

161029 - 2016-10-29
-------------------

First release
