bleeding-edge-toolchain [![Build Status](https://travis-ci.org/FreddieChopin/bleeding-edge-toolchain.svg)](https://travis-ci.org/FreddieChopin/bleeding-edge-toolchain)
=======================

All-in-one script to build bleeding-edge-toolchain for ARM microcontrollers.

[bleeding-edge-toolchain - what it's all about?](http://www.freddiechopin.info/en/articles/35-arm/87-bleeding-edge-toolchain-o-co-chodzi)

Toolchain for Linux
-------------------

Due to the fact that building a binary on "Linux distribution A" that would work on "Linux distribution B" (where
"Linux distribution B" may just be "Linux distribution A 6 months later after a few upgrades") is really hard
(impossible?), there will be no binary packages for Linux. This script and some spare CPU time (~30 minutes) is all you
need.

To build native toolchain for Linux just run the script with no arguments:

`./build-bleeding-edge-toolchain.sh`

Most of the tools required by the script should be already present in your system, but some may be missing. Generally
the tools listed below should be enough to successfully execute this script:
- obvious tools needed to compile anything - like `gcc`, `binutils`, `make` and `coreutils`,
- `m4`, which is required to execute `configure` scripts,
- `curl`, used to download the source tarballs of toolchain components,
- `tar`, used to extract source tarballs and to compress compiled toolchain,
- `makeinfo`, used to generate documentation - it is usually present in `texinfo` package,
- `python`, required by GDB, may be either version 2 or 3, but should contain headers and libraries, so you may need
some kind of "development" and/or "library" package, depending on your system.

Exact set of required packages will be different on each system, but on a fresh Ubuntu installation you are going to
need just these packages: `build-essential`, `m4`, `curl`, `python2.7`, `python2.7-dev` and `libpython2.7-stdlib`
(credits for checking that go to Alexandre - thanks!).

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

Minimalistic how-to compile for fresh Ubuntu or Mint instalation
----------------------------------------------------------------

```
sudo apt-get update
sudo apt-get dist-upgrade

sudo apt-get install build-essential m4 curl texinfo \
  python2.7 python2.7-dev mingw-w64 libncurses5-dev p7zip-full git

git clone https://github.com/FreddieChopin/bleeding-edge-toolchain.git
cd bleeding-edge-toolchain
./build-bleeding-edge-toolchain.sh --enable-win32 --enable-win64
```
