bleeding-edge-toolchain
=======================

All-in-one script to build bleeding-edge-toolchain for ARM microcontrollers.

It does not include CMSIS though. That can be retrieved separately from https://github.com/ARM-software/CMSIS_5/releases.

[bleeding-edge-toolchain - what it's all about?](http://www.freddiechopin.info/en/articles/35-arm/87-bleeding-edge-toolchain-o-co-chodzi)

Toolchain for Linux
-------------------

Due to the fact that building a binary on "Linux distribution A" that would work on "Linux distribution B" (where
"Linux distribution B" may just be "Linux distribution A 6 months later after a few upgrades") is really hard
(impossible?), there will be no binary packages for Linux. This script and some spare CPU time (~2 hours) is all you
need.

To build native toolchain for Linux just run the script with no arguments:

`./build-bleeding-edge-toolchain.sh`

Most of the tools required by the script should be already present in your system, but some may be missing. Generally
the tools listed below should be enough to successfully execute this script:
- obvious tools needed to compile anything - like `gcc`, `binutils`, `make` and `coreutils`,
- `m4`, which is required to execute `configure` scripts,
- `curl`, used to download the source tarballs of toolchain components,
- `tar`, used to extract source tarballs and to compress compiled toolchain,
- `texinfo` and `texlive`, (optional) used to generate documentation,
- `python`, required by GDB, may be either version 2 or 3, but should contain headers and libraries, so you may need
some kind of "development" and/or "library" package, depending on your system.

Exact set of required packages will be different on each system, but on a fresh Ubuntu installation you are going to
need just these packages: `curl`, `m4`, `python2.7-dev` and optionally: `texinfo` and `texlive`.

Toolchain for Windows
---------------------

As Windows is at the opposite end of spectrum when it comes to binary compatibility, the packages for 32-bit and 64-bit
Windows are available on [Freddie Chopin's website](http://www.freddiechopin.info/) in Download > Software >
bleeding-edge-toolchain. If you choose the easy path, just download an archive, extract it with 7-zip and add `.../bin`
folder to your system's `PATH` environment variable.

If you want to _also_ build toolchain for 32-bit and/or 64-bit Windows pass `--enable-win32` and/or `--enable-win64` as
arguments for the script, like that:

`./build-bleeding-edge-toolchain.sh --enable-win32 --enable-win64`

Such compilation has more dependencies:
- `Mingw-w64`, namely `i686-w64-mingw32-gcc` (for 32-bit version) and/or `x86_64-w64-mingw32-gcc` (for 64-bit version)
with their own dependencies (binutils, headers, ...),
- `libtermcap` and `libwinpthread` compiled for `Mingw-w64`,
- `p7zip`, used to compress the toolchain into an archive in `.7z` format.

Additional options
------------------

- `--keep-build-folders` will cause all build folders to be left intact after the build, by default - if this option is
not provided - all build folders are removed as soon as they are not needed anymore;
- `--resume` will try to resume the last (interrupted) build instead of starting from scratch; be advised that this
option is experimental and may not work reliably in all possible cases - if in doubt or in case of strange errors just
don't use it to perform a clean build;
- `--skip-documentation` will skip building html/pdf documentation in the subprojects, by default - if this option is
not provided - the documentation is built, requiring texlive/texinfo;
- `--skip-nano-libraries` will skip building of "nano" libraries, by default - if this option is not provided - "nano"
libraries will be built, making the whole process significantly longer;
- `--quiet` will make the build slightly less noisy;
