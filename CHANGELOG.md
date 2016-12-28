Change Log
==========

All notable changes to this project will be documented in this file.

[Unreleased](https://github.com/FreddieChopin/bleeding-edge-toolchain/compare/161029...HEAD)
--------------------------------------------------------------------------------------------

### Added

- Support for "nano" variant of libraries.
- Big-endian version of multilib for *ARMv7-R* targets (by Jiri Dobry).

### Changed

- More detailed info about requirements to build the toolchain in README.md.
- Updated gcc to version 6.3.0.
- Updated newlib to version 2.5.0.
- Updated isl to version 0.16.1.

### Fixed

- Removed duplicate content in gcc multilib patch (by Jiri Dobry).
- Fixed brackets in gcc multilib patch, which restores libraries for *ARMv7-R* targets (by Jiri Dobry).

161029 - 2016-10-29
-------------------

First release
