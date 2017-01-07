Change Log
==========

All notable changes to this project will be documented in this file.

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
