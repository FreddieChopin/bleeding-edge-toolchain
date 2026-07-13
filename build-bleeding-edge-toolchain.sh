#!/bin/sh
# shellcheck disable=SC2030,SC2031

#
# file: build-bleeding-edge-toolchain.sh
#
# author: Copyright (C) 2016-2024 Freddie Chopin https://freddiechopin.info https://distortec.com
#
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
# distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
#

set -eu

# https://www.gnu.org/software/binutils/
binutilsVersion="2.46.1"
# https://libexpat.github.io/
expatVersion="2.8.2"
# https://gcc.gnu.org/
gccVersion="14.3.0"
# https://sourceware.org/gdb/
gdbVersion="17.2"
# https://gmplib.org/
gmpVersion="6.3.0"
# https://libisl.sourceforge.io/
islVersion="0.28"
# https://savannah.gnu.org/projects/libiconv/
libiconvVersion="1.18"
# https://www.multiprecision.org/
mpcVersion="1.4.1"
# https://www.mpfr.org/
mpfrVersion="4.2.2"
# https://sourceware.org/newlib/
newlibVersion="4.6.0.20260123"
# https://www.python.org/
pythonVersion="3.14.6"
# https://zlib.net/
zlibVersion="1.3.2"

top="$(pwd)"
buildNative="buildNative"
buildWin32="buildWin32"
buildWin64="buildWin64"
installNative="installNative"
installWin32="installWin32"
installWin64="installWin64"
nanoLibraries="nanoLibraries"
prerequisites="prerequisites"
sources="sources"

binutils="binutils-${binutilsVersion}"
binutilsArchive="${binutils}.tar.xz"
expat="expat-${expatVersion}"
expatArchive="${expat}.tar.bz2"
gcc="gcc-${gccVersion}"
gccArchive="${gcc}.tar.xz"
gdb="gdb-${gdbVersion}"
gdbArchive="${gdb}.tar.xz"
gmp="gmp-${gmpVersion}"
gmpArchive="${gmp}.tar.xz"
isl="isl-${islVersion}"
islArchive="${isl}.tar.xz"
libiconv="libiconv-${libiconvVersion}"
libiconvArchive="${libiconv}.tar.gz"
mpc="mpc-${mpcVersion}"
mpcArchive="${mpc}.tar.xz"
mpfr="mpfr-${mpfrVersion}"
mpfrArchive="${mpfr}.tar.xz"
newlib="newlib-${newlibVersion}"
newlibArchive="${newlib}.tar.gz"
pythonWin32="python-${pythonVersion}-win32"
pythonArchiveWin32="${pythonWin32}.nupkg"
pythonWin64="python-${pythonVersion}-win64"
pythonArchiveWin64="${pythonWin64}.nupkg"
zlib="zlib-${zlibVersion}"
zlibArchive="${zlib}.tar.gz"

gnuMirror="https://ftpmirror.gnu.org"
pkgversion="bleeding-edge-toolchain"
target="arm-none-eabi"
package="${target}-${gcc}-$(date +'%y%m%d')"
packageArchiveNative="${package}.tar.xz"
packageArchiveWin32="${package}-win32.7z"
packageArchiveWin64="${package}-win64.7z"

bold=
normal=
if [ -n "${TERM-}" ]; then
	bold="$(tput bold)"
	normal="$(tput sgr0)"
fi
uname="$(uname)"

if [ "${uname}" = "Darwin" ]; then
	nproc="$(sysctl -n hw.ncpu)"
	hostSystem="$(uname -sm)"
else
	nproc="$(nproc)"
	hostSystem="$(uname -mo)"
fi

enableWin32="n"
enableWin64="n"
keepBuildFolders="n"
skipGdb="n"
skipNanoLibraries="n"
buildDocumentation="y"
quiet="n"
resume="n"
while [ "${#}" -gt 0 ]; do
	case "${1}" in
		--enable-win32)
			enableWin32="y"
			;;
		--enable-win64)
			enableWin64="y"
			;;
		--keep-build-folders)
			keepBuildFolders="y"
			;;
		--resume)
			resume="y"
			;;
		--skip-documentation)
			buildDocumentation="n"
			;;
		--skip-gdb)
			skipGdb="y"
			;;
		--skip-nano-libraries)
			skipNanoLibraries="y"
			;;
		--quiet)
			quiet="y"
			;;
		*)
			printf "Usage: %s\n" "${0}" >&2
			printf "\t\t[--enable-win32] [--enable-win64] [--keep-build-folders] [--resume]\n" >&2
			printf "\t\t[--skip-documentation] [--skip-gdb] [--skip-nano-libraries] [--quiet]\n" >&2
			exit 1
			;;
	esac
	shift
done

documentationTypes=""
if [ "${buildDocumentation}" = "y" ]; then
	documentationTypes="html pdf"
fi

quietConfigureOptions=""
if [ "${quiet}" = "y" ]; then
	quietConfigureOptions="--quiet --enable-silent-rules"
	export MAKEFLAGS="--quiet"
	export GNUMAKEFLAGS="--quiet"
fi

BASE_CPPFLAGS="-pipe"
BASE_LDFLAGS=
BASE_CFLAGS_FOR_TARGET="-pipe -ffunction-sections -fdata-sections"
BASE_CXXFLAGS_FOR_TARGET="-pipe -ffunction-sections -fdata-sections -fno-exceptions"

messageA() {
	echo "${bold}********** ${1}${normal}"
}

messageB() {
	echo "${bold}---------- ${1}${normal}"
}

maybeDelete() {
	if [ -f "${1}" ] || [ -h "${1}" ]; then
		rm -f "${1:?}"
	elif [ -d "${1}" ]; then
		rm -rf "${1:?}"
	fi
}

buildZlib() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	makeOptions="${3}"
	makeInstallOptions="${4}"
	tagFileBase="${top}/${buildFolder}/zlib"
	messageA "${bannerPrefix}${zlib}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${zlib}"
		cp -R "${sources}/${zlib}" "${buildFolder}"
		cd "${buildFolder}/${zlib}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${zlib} configure"
		./configure --static --prefix="${top}/${buildFolder}/${prerequisites}/${zlib}"
		messageB "${bannerPrefix}${zlib} make"
		eval "make ${makeOptions} \"-j${nproc}\""
		messageB "${bannerPrefix}${zlib} make install"
		eval "make ${makeInstallOptions} install"
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${zlib} remove build folder"
			maybeDelete "${buildFolder}/${zlib}"
		fi
	fi
	)
}

buildGmp() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	configureOptions="${3}"
	tagFileBase="${top}/${buildFolder}/gmp"
	messageA "${bannerPrefix}${gmp}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gmp}"
		mkdir -p "${buildFolder}/${gmp}"
		cd "${buildFolder}/${gmp}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${gmp} configure"
		eval "\"${top}/${sources}/${gmp}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
			--enable-cxx \
			--disable-shared"
		messageB "${bannerPrefix}${gmp} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${gmp} make install"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${gmp} remove build folder"
			maybeDelete "${buildFolder}/${gmp}"
		fi
	fi
	)
}

buildMpfr() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	configureOptions="${3}"
	tagFileBase="${top}/${buildFolder}/mpfr"
	messageA "${bannerPrefix}${mpfr}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${mpfr}"
		mkdir -p "${buildFolder}/${mpfr}"
		cd "${buildFolder}/${mpfr}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${mpfr} configure"
		eval "\"${top}/${sources}/${mpfr}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\" \
			--disable-shared \
			--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\""
		messageB "${bannerPrefix}${mpfr} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${mpfr} make install"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${mpfr} remove build folder"
			maybeDelete "${buildFolder}/${mpfr}"
		fi
	fi
	)
}

buildMpc() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	configureOptions="${3}"
	tagFileBase="${top}/${buildFolder}/mpc"
	messageA "${bannerPrefix}${mpc}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${mpc}"
		mkdir -p "${buildFolder}/${mpc}"
		cd "${buildFolder}/${mpc}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${mpc} configure"
		eval "\"${top}/${sources}/${mpc}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${mpc}\" \
			--disable-shared \
			--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
			--with-mpfr=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\""
		messageB "${bannerPrefix}${mpc} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${mpc} make install"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${mpc} remove build folder"
			maybeDelete "${buildFolder}/${mpc}"
		fi
	fi
	)
}

buildIsl() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	configureOptions="${3}"
	tagFileBase="${top}/${buildFolder}/isl"
	messageA "${bannerPrefix}${isl}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${isl}"
		mkdir -p "${buildFolder}/${isl}"
		cd "${buildFolder}/${isl}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${isl} configure"
		eval "\"${top}/${sources}/${isl}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${isl}\" \
			--disable-shared \
			--with-gmp-prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\""
		messageB "${bannerPrefix}${isl} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${isl} make install"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${isl} remove build folder"
			maybeDelete "${buildFolder}/${isl}"
		fi
	fi
	)
}

buildExpat() {
	(
	buildFolder="${1}"
	bannerPrefix="${2}"
	configureOptions="${3}"
	tagFileBase="${top}/${buildFolder}/expat"
	messageA "${bannerPrefix}${expat}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${expat}"
		mkdir -p "${buildFolder}/${expat}"
		cd "${buildFolder}/${expat}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${expat} configure"
		eval "\"${top}/${sources}/${expat}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${expat}\" \
			--disable-shared"
		messageB "${bannerPrefix}${expat} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${expat} make install"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${expat} remove build folder"
			maybeDelete "${buildFolder}/${expat}"
		fi
	fi
	)
}

buildBinutils() {
	(
	buildFolder="${1}"
	installFolder="${2}"
	bannerPrefix="${3}"
	configureOptions="${4}"
	documentations="${5}"
	tagFileBase="${top}/${buildFolder}/binutils"
	messageA "${bannerPrefix}${binutils}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${binutils}"
		mkdir -p "${buildFolder}/${binutils}"
		cd "${buildFolder}/${binutils}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${binutils} configure"
		eval "\"${top}/${sources}/${binutils}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--target=\"${target}\" \
			--prefix=\"${top}/${installFolder}\" \
			--docdir=\"${top}/${installFolder}/share/doc\" \
			--disable-nls \
			--enable-interwork \
			--enable-multilib \
			--enable-plugins \
			--with-system-zlib \
			--with-pkgversion=\"${pkgversion}\""
		messageB "${bannerPrefix}${binutils} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${binutils} make install"
		make install
		for documentation in ${documentations}; do
			messageB "${bannerPrefix}${binutils} make install-${documentation}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${binutils} remove build folder"
			maybeDelete "${buildFolder}/${binutils}"
		fi
	fi
	)
}

buildGcc() {
	(
	buildFolder="${1}"
	installFolder="${2}"
	bannerPrefix="${3}"
	configureOptions="${4}"
	tagFileBase="${top}/${buildFolder}/gcc"
	messageA "${bannerPrefix}${gcc}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gcc}"
		mkdir -p "${buildFolder}/${gcc}"
		cd "${buildFolder}/${gcc}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${gcc} configure"
		eval "\"${top}/${sources}/${gcc}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--target=\"${target}\" \
			--prefix=\"${top}/${installFolder}\" \
			--libexecdir=\"${top}/${installFolder}/lib\" \
			--disable-decimal-float \
			--disable-libffi \
			--disable-libgomp \
			--disable-libmudflap \
			--disable-libquadmath \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--disable-nls \
			--disable-shared \
			--disable-threads \
			--disable-tls \
			--with-newlib \
			--with-gnu-as \
			--with-gnu-ld \
			--with-sysroot=\"${top}/${installFolder}/${target}\" \
			--with-system-zlib \
			--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
			--with-mpfr=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\" \
			--with-mpc=\"${top}/${buildFolder}/${prerequisites}/${mpc}\" \
			--with-isl=\"${top}/${buildFolder}/${prerequisites}/${isl}\" \
			--with-pkgversion=\"${pkgversion}\" \
			--with-multilib-list=rmprofile"
		messageB "${bannerPrefix}${gcc} make all-gcc"
		make "-j${nproc}" all-gcc
		messageB "${bannerPrefix}${gcc} make install-gcc"
		make install-gcc
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${gcc} remove build folder"
			maybeDelete "${buildFolder}/${gcc}"
		fi
	fi
	)
}

buildNewlib() {
	(
	suffix="${1}"
	optimization="${2}"
	configureOptions="${3}"
	documentations="${4}"
	tagFileBase="${top}/${buildNative}/newlib${suffix}"
	messageA "${newlib}${suffix}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildNative}/${newlib}${suffix}"
		mkdir -p "${buildNative}/${newlib}${suffix}"
		cd "${buildNative}/${newlib}${suffix}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		export PATH="${top}/${installNative}/bin:${PATH-}"
		export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
		messageB "${newlib}${suffix} configure"
		eval "\"${top}/${sources}/${newlib}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--target=\"${target}\" \
			--disable-newlib-supplied-syscalls \
			--enable-newlib-reent-small \
			--disable-newlib-fvwrite-in-streamio \
			--disable-newlib-fseek-optimization \
			--disable-newlib-wide-orient \
			--disable-newlib-unbuf-stream-opt \
			--enable-newlib-global-atexit \
			--enable-newlib-retargetable-locking \
			--enable-newlib-global-stdio-streams \
			--disable-nls"
		messageB "${newlib}${suffix} make"
		make "-j${nproc}"
		messageB "${newlib}${suffix} make install"
		make install
		for documentation in ${documentations}; do
			cd "${target}/newlib"
			messageB "${newlib}${suffix} make install-${documentation}"
			make "install-${documentation}"
			cd ../..
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${newlib}${suffix} remove build folder"
			maybeDelete "${buildNative}/${newlib}${suffix}"
		fi
	fi
	)
}

buildGccFinal() {
	(
	suffix="${1}"
	optimization="${2}"
	installFolder="${3}"
	documentations="${4}"
	tagFileBase="${top}/${buildNative}/gcc${suffix}"
	messageA "${gcc}${suffix}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildNative}/${gcc}${suffix}"
		mkdir -p "${buildNative}/${gcc}${suffix}"
		cd "${buildNative}/${gcc}${suffix}"
		export CPPFLAGS="-I\"${top}/${buildNative}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildNative}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
		export CXXFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CXXFLAGS_FOR_TARGET-} ${CXXFLAGS_FOR_TARGET-}"
		messageB "${gcc}${suffix} configure"
		eval "\"${top}/${sources}/${gcc}/configure\" \
			${quietConfigureOptions} \
			--target=\"${target}\" \
			--prefix=\"${top}/${installFolder}\" \
			--docdir=\"${top}/${installFolder}/share/doc\" \
			--libexecdir=\"${top}/${installFolder}/lib\" \
			--enable-languages=c,c++ \
			--disable-libstdcxx-verbose \
			--enable-plugins \
			--disable-decimal-float \
			--disable-libffi \
			--disable-libgomp \
			--disable-libmudflap \
			--disable-libquadmath \
			--disable-libssp \
			--disable-libstdcxx-pch \
			--disable-nls \
			--disable-shared \
			--disable-threads \
			--disable-tls \
			--with-gnu-as \
			--with-gnu-ld \
			--with-newlib \
			--with-headers=yes \
			--with-sysroot=\"${top}/${installFolder}/${target}\" \
			--with-system-zlib \
			--with-gmp=\"${top}/${buildNative}/${prerequisites}/${gmp}\" \
			--with-mpfr=\"${top}/${buildNative}/${prerequisites}/${mpfr}\" \
			--with-mpc=\"${top}/${buildNative}/${prerequisites}/${mpc}\" \
			--with-isl=\"${top}/${buildNative}/${prerequisites}/${isl}\" \
			--with-pkgversion=\"${pkgversion}\" \
			--with-multilib-list=rmprofile"
		messageB "${gcc}${suffix} make"
		make "-j${nproc}" INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
		messageB "${gcc}${suffix} make install"
		make install
		for documentation in ${documentations}; do
			messageB "${gcc}${suffix} make install-${documentation}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${gcc}${suffix} remove build folder"
			maybeDelete "${buildNative}/${gcc}${suffix}"
		fi
	fi
	)
}

copyNanoLibraries() {
	(
	source="${1}"
	destination="${2}"
	messageA "\"nano\" libraries copy"
	multilibs=$("${destination}/bin/${target}-gcc" -print-multi-lib)
	sourcePrefix="${source}/${target}/lib"
	destinationPrefix="${destination}/${target}/lib"
	for multilib in ${multilibs}; do
		multilib="${multilib%%;*}"
		sourceDirectory="${sourcePrefix}/${multilib}"
		destinationDirectory="${destinationPrefix}/${multilib}"
		mkdir -p "${destinationDirectory}"
		cp "${sourceDirectory}/libc.a" "${destinationDirectory}/libc_nano.a"
		cp "${sourceDirectory}/libg.a" "${destinationDirectory}/libg_nano.a"
		cp "${sourceDirectory}/librdimon.a" "${destinationDirectory}/librdimon_nano.a"
		cp "${sourceDirectory}/libstdc++.a" "${destinationDirectory}/libstdc++_nano.a"
		cp "${sourceDirectory}/libsupc++.a" "${destinationDirectory}/libsupc++_nano.a"
	done

	mkdir -p "${destination}/${target}/include/newlib-nano"
	cp "${source}/${target}/include/newlib.h" "${destination}/${target}/include/newlib-nano"

	if [ "${keepBuildFolders}" = "n" ]; then
		messageB "\"nano\" libraries remove install folder"
		maybeDelete "${top}/${buildNative}/${nanoLibraries}"
	fi
	)
}

buildGdb() {
	(
	buildFolder="${1}"
	installFolder="${2}"
	bannerPrefix="${3}"
	configureOptions="${4}"
	documentations="${5}"
	tagFileBase="${top}/${buildFolder}/gdb-py"
	case "${configureOptions}" in
		*"--with-python=no"*)
			tagFileBase="${top}/${buildFolder}/gdb"
			;;
	esac
	messageA "${bannerPrefix}${gdb}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gdb}"
		mkdir -p "${buildFolder}/${gdb}"
		cd "${buildFolder}/${gdb}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		messageB "${bannerPrefix}${gdb} configure"
		eval "\"${top}/${sources}/${gdb}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--target=\"${target}\" \
			--prefix=\"${top}/${installFolder}\" \
			--docdir=\"${top}/${installFolder}/share/doc\" \
			--disable-nls \
			--disable-sim \
			--with-lzma=no \
			--with-guile=no \
			--with-system-gdbinit=\"${top}/${installFolder}/${target}/lib/gdbinit\" \
			--with-system-zlib \
			--with-expat=yes \
			--with-libexpat-prefix=\"${top}/${buildFolder}/${prerequisites}/${expat}\" \
			--with-mpfr=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\" \
			--with-gdb-datadir=\"'\\\${prefix}'/${target}/share/gdb\" \
			--with-pkgversion=\"${pkgversion}\""
		messageB "${bannerPrefix}${gdb} make"
		make "-j${nproc}"
		messageB "${bannerPrefix}${gdb} make install"
		make install
		for documentation in ${documentations}; do
			messageB "${bannerPrefix}${gdb} make install-${documentation}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			messageB "${bannerPrefix}${gdb} remove build folder"
			maybeDelete "${buildFolder}/${gdb}"
		fi
	fi
	)
}

postCleanup() {
	(
	installFolder="${1}"
	bannerPrefix="${2}"
	hostSystem="${3}"
	extraComponents="${4}"
	if [ "${uname}" = "Darwin" ]; then
		buildSystem="$(uname -srvm)"
	else
		buildSystem="$(uname -srvmo)"
	fi
	messageA "${bannerPrefix}Post-cleanup"
	maybeDelete "${installFolder}/include"
	find "${installFolder}" -name '*.la' -exec rm -rf {} +
	cat > "${installFolder}/info.txt" <<- EOF
	${pkgversion}
	build date: $(date +'%Y-%m-%d')
	build system: ${buildSystem}
	host system: ${hostSystem}
	target system: ${target}
	compiler: $(${CC-gcc} --version | head -n1)

	Toolchain components:
	- ${gcc}
	- ${newlib}
	- ${binutils}
	- ${gdb}
	$(printf -- "- %s\n- %s\n- %s\n- %s\n- %s\n- %s\n%b" "${expat}" "${gmp}" "${isl}" "${mpc}" "${mpfr}" "${zlib}" "${extraComponents}" | sort)

	This package and info about it can be found on bleeding-edge-toolchain's website:
	https://github.com/FreddieChopin/bleeding-edge-toolchain
	EOF
	cp "${0}" "${installFolder}"
	)
}

if [ "${resume}" = "y" ]; then
	messageA "Resuming last build"
else
	messageA "Cleanup"
	maybeDelete "${buildNative}"
	maybeDelete "${installNative}"
	mkdir -p "${buildNative}"
	mkdir -p "${installNative}"
	maybeDelete "${buildWin32}"
	maybeDelete "${installWin32}"
	if [ "${enableWin32}" = "y" ]; then
		mkdir -p "${buildWin32}"
		mkdir -p "${installWin32}"
	fi
	maybeDelete "${buildWin64}"
	maybeDelete "${installWin64}"
	if [ "${enableWin64}" = "y" ]; then
		mkdir -p "${buildWin64}"
		mkdir -p "${installWin64}"
	fi
	mkdir -p "${sources}"
	find "${sources}" -mindepth 1 -maxdepth 1 -type f ! -name "${binutilsArchive}" \
		! -name "${expatArchive}" \
		! -name "${gccArchive}" \
		! -name "${gdbArchive}" \
		! -name "${gmpArchive}" \
		! -name "${islArchive}" \
		! -name "${libiconvArchive}" \
		! -name "${mpcArchive}" \
		! -name "${mpfrArchive}" \
		! -name "${newlibArchive}" \
		! -name "${pythonArchiveWin32}" \
		! -name "${pythonArchiveWin64}" \
		! -name "${zlibArchive}" \
		-exec rm -rf {} +
	find "${sources}" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
fi

messageA "Download"
mkdir -p "${sources}"
cd "${sources}"
download() {
	ret=0
	if [ ! -f "${1}_downloaded" ]; then
		messageB "Downloading ${1}"
		curl -L -o "${1}" -C - --connect-timeout 30 -Y 1024 -y 30 "${2}" || ret="${?}"
		if [ "${ret}" -eq 33 ]; then
			echo 'This happens if the file is complete, continuing...'
		elif [ "${ret}" -ne 0 ]; then
			exit "${ret}"
		fi
		touch "${1}_downloaded"
	fi
}
download "${binutilsArchive}" "${gnuMirror}/binutils/${binutilsArchive}"
download "${expatArchive}" "https://github.com/libexpat/libexpat/releases/download/$(echo "R_${expatVersion}" | sed 's/\./_/g')/${expatArchive}"
if [ "${gccVersion#*-}" = "${gccVersion}" ]; then
	download "${gccArchive}" "${gnuMirror}/gcc/${gcc}/${gccArchive}"
else
	download "${gccArchive}" "https://gcc.gnu.org/pub/gcc/snapshots/${gccVersion}/${gccArchive}"
fi
if [ "${skipGdb}" = "n" ]; then
	download "${gdbArchive}" "${gnuMirror}/gdb/${gdbArchive}"
fi
download "${gmpArchive}" "${gnuMirror}/gmp/${gmpArchive}"
download "${islArchive}" "https://libisl.sourceforge.io/${islArchive}"
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	download "${libiconvArchive}" "${gnuMirror}/libiconv/${libiconvArchive}"
fi
download "${mpcArchive}" "${gnuMirror}/mpc/${mpcArchive}"
download "${mpfrArchive}" "${gnuMirror}/mpfr/${mpfrArchive}"
download "${newlibArchive}" "https://sourceware.org/pub/newlib/${newlibArchive}"
if [ "${enableWin32}" = "y" ]; then
	download "${pythonArchiveWin32}" "https://www.nuget.org/api/v2/package/pythonx86/${pythonVersion}"
fi
if [ "${enableWin64}" = "y" ]; then
	download "${pythonArchiveWin64}" "https://www.nuget.org/api/v2/package/python/${pythonVersion}"
fi
download "${zlibArchive}" "https://www.zlib.net/fossils/${zlibArchive}"
cd "${top}"

messageA "Extract"
cd "${sources}"
extract() {
	if [ ! -f "${1}_extracted" ]; then
		messageB "Extracting ${1}"
		tar -xf "${1}"
		touch "${1}_extracted"
	fi
}
extract "${binutilsArchive}"
extract "${expatArchive}"
extract "${gccArchive}"
if [ ! -f "${gcc}_patched" ]; then
	messageB "Patching ${gcc}"
	(
	cd "${gcc}"
patch -p1 << 'EOF'
From 1f0224e8ddb3d3d0bf4c7a11769b193a4df5cc37 Mon Sep 17 00:00:00 2001
From: Jakub Jelinek <jakub@redhat.com>
Date: Fri, 21 Nov 2025 16:25:58 +0100
Subject: [PATCH] libcody: Make it buildable by C++11 to C++26

The following builds with -std=c++11 and c++14 and c++17 and c++20 and c++23
and c++26.

I see the u8 string literals are mixed e.g. with strerror, so in
-fexec-charset=IBM1047 there will still be garbage, so am not 100% sure if
the u8 literals everywhere are worth it either.

2025-11-21  Jakub Jelinek  <jakub@redhat.com>

	* cody.hh (S2C): For __cpp_char8_t >= 201811 use char8_t instead of
	char in argument type.
	(MessageBuffer::Space): Revert 2025-11-15 change.
	(MessageBuffer::Append): For __cpp_char8_t >= 201811 add overload
	with char8_t const * type of first argument.
	(Packet::Packet): Similarly for first argument.
	* client.cc (CommunicationError, Client::ProcessResponse,
	Client::Connect, ConnectResponse, PathnameResponse, OKResponse,
	IncludeTranslateResponse): Cast u8 string literals to (const char *)
	where needed.
	* server.cc (Server::ProcessRequests, ConnectRequest): Likewise.

(cherry picked from commit 07a767c7a50d1daae8ef7d4aba73fe53ad40c0b7)

Upstream: https://gcc.gnu.org/git/?p=gcc.git;a=commit;h=1f0224e8ddb3d3d0bf4c7a11769b193a4df5cc37

Signed-off-by: Bernd Kuhls <bernd@kuhls.net>
---
 libcody/client.cc | 36 +++++++++++++++++++-----------------
 libcody/cody.hh   | 22 ++++++++++++++++++++++
 libcody/server.cc | 28 ++++++++++++++--------------
 3 files changed, 55 insertions(+), 31 deletions(-)

diff --git a/libcody/client.cc b/libcody/client.cc
index ae69d190cb77..147fecdbe500 100644
--- a/libcody/client.cc
+++ b/libcody/client.cc
@@ -97,7 +97,7 @@ int Client::CommunicateWithServer ()

 static Packet CommunicationError (int err)
 {
-  std::string e {u8"communication error:"};
+  std::string e {(const char *) u8"communication error:"};
   e.append (strerror (err));

   return Packet (Client::PC_ERROR, std::move (e));
@@ -110,33 +110,34 @@ Packet Client::ProcessResponse (std::vector<std::string> &words,
     {
       if (e == EINVAL)
 	{
-	  std::string msg (u8"malformed string '");
+	  std::string msg ((const char *) u8"malformed string '");
 	  msg.append (words[0]);
-	  msg.append (u8"'");
+	  msg.append ((const char *) u8"'");
 	  return Packet (Client::PC_ERROR, std::move (msg));
 	}
       else
-	return Packet (Client::PC_ERROR, u8"missing response");
+	return Packet (Client::PC_ERROR, (const char *) u8"missing response");
     }

   Assert (!words.empty ());
-  if (words[0] == u8"ERROR")
+  if (words[0] == (const char *) u8"ERROR")
     return Packet (Client::PC_ERROR,
-		   words.size () == 2 ? words[1]: u8"malformed error response");
+		   words.size () == 2 ? words[1]
+		   : (const char *) u8"malformed error response");

   if (isLast && !read.IsAtEnd ())
     return Packet (Client::PC_ERROR,
-		   std::string (u8"unexpected extra response"));
+		   std::string ((const char *) u8"unexpected extra response"));

   Assert (code < Detail::RC_HWM);
   Packet result (responseTable[code] (words));
   result.SetRequest (code);
   if (result.GetCode () == Client::PC_ERROR && result.GetString ().empty ())
     {
-      std::string msg {u8"malformed response '"};
+      std::string msg {(const char *) u8"malformed response '"};

       read.LexedLine (msg);
-      msg.append (u8"'");
+      msg.append ((const char *) u8"'");
       result.GetString () = std::move (msg);
     }
   else if (result.GetCode () == Client::PC_CONNECT)
@@ -199,7 +200,7 @@ Packet Client::Connect (char const *agent, char const *ident,
 			  size_t alen, size_t ilen)
 {
   write.BeginLine ();
-  write.AppendWord (u8"HELLO");
+  write.AppendWord ((const char *) u8"HELLO");
   write.AppendInteger (Version);
   write.AppendWord (agent, true, alen);
   write.AppendWord (ident, true, ilen);
@@ -211,7 +212,8 @@ Packet Client::Connect (char const *agent, char const *ident,
 // HELLO $version $agent [$flags]
 Packet ConnectResponse (std::vector<std::string> &words)
 {
-  if (words[0] == u8"HELLO" && (words.size () == 3 || words.size () == 4))
+  if (words[0] == (const char *) u8"HELLO"
+      && (words.size () == 3 || words.size () == 4))
     {
       char *eptr;
       unsigned long val = strtoul (words[1].c_str (), &eptr, 10);
@@ -247,7 +249,7 @@ Packet Client::ModuleRepo ()
 // PATHNAME $dir | ERROR
 Packet PathnameResponse (std::vector<std::string> &words)
 {
-  if (words[0] == u8"PATHNAME" && words.size () == 2)
+  if (words[0] == (const char *) u8"PATHNAME" && words.size () == 2)
     return Packet (Client::PC_PATHNAME, std::move (words[1]));

   return Packet (Client::PC_ERROR, u8"");
@@ -256,7 +258,7 @@ Packet PathnameResponse (std::vector<std::string> &words)
 // OK or ERROR
 Packet OKResponse (std::vector<std::string> &words)
 {
-  if (words[0] == u8"OK")
+  if (words[0] == (const char *) u8"OK")
     return Packet (Client::PC_OK);
   else
     return Packet (Client::PC_ERROR,
@@ -319,11 +321,11 @@ Packet Client::IncludeTranslate (char const *include, Flags flags, size_t ilen)
 // PATHNAME $cmifile
 Packet IncludeTranslateResponse (std::vector<std::string> &words)
 {
-  if (words[0] == u8"BOOL" && words.size () == 2)
+  if (words[0] == (const char *) u8"BOOL" && words.size () == 2)
     {
-      if (words[1] == u8"FALSE")
-	return Packet (Client::PC_BOOL, 0);
-      else if (words[1] == u8"TRUE")
+      if (words[1] == (const char *) u8"FALSE")
+	return Packet (Client::PC_BOOL);
+      else if (words[1] == (const char *) u8"TRUE")
 	return Packet (Client::PC_BOOL, 1);
       else
 	return Packet (Client::PC_ERROR, u8"");
diff --git a/libcody/cody.hh b/libcody/cody.hh
index 789ce9e70b75..93bce93aa94d 100644
--- a/libcody/cody.hh
+++ b/libcody/cody.hh
@@ -47,12 +47,21 @@ namespace Detail  {

 // C++11 doesn't have utf8 character literals :(

+#if __cpp_char8_t >= 201811
+template<unsigned I>
+constexpr char S2C (char8_t const (&s)[I])
+{
+  static_assert (I == 2, "only single octet strings may be converted");
+  return s[0];
+}
+#else
 template<unsigned I>
 constexpr char S2C (char const (&s)[I])
 {
   static_assert (I == 2, "only single octet strings may be converted");
   return s[0];
 }
+#endif

 /// Internal buffering class.  Used to concatenate outgoing messages
 /// and Lex incoming ones.
@@ -123,6 +132,13 @@ public:
       Space ();
     Append (str, maybe_quote, len);
   }
+#if __cpp_char8_t >= 201811
+  void AppendWord (char8_t const *str, bool maybe_quote = false,
+		   size_t len = ~size_t (0))
+  {
+    AppendWord ((const char *) str, maybe_quote, len);
+  }
+#endif
   /// Add a word as with AppendWord
   /// @param str the string to append
   /// @param maybe_quote string might need quoting, as for Append
@@ -264,6 +280,12 @@ public:
     : string (s), cat (STRING), code (c)
   {
   }
+#if __cpp_char8_t >= 201811
+  Packet (unsigned c, const char8_t *s)
+    : string ((const char *) s), cat (STRING), code (c)
+  {
+  }
+#endif
   Packet (unsigned c, std::vector<std::string> &&v)
     : vector (std::move (v)), cat (VECTOR), code (c)
   {
diff --git a/libcody/server.cc b/libcody/server.cc
index e2fa069bb933..c18469fae843 100644
--- a/libcody/server.cc
+++ b/libcody/server.cc
@@ -36,12 +36,12 @@ static RequestPair
   const requestTable[Detail::RC_HWM] =
   {
     // Same order as enum RequestCode
-    RequestPair {u8"HELLO", nullptr},
-    RequestPair {u8"MODULE-REPO", ModuleRepoRequest},
-    RequestPair {u8"MODULE-EXPORT", ModuleExportRequest},
-    RequestPair {u8"MODULE-IMPORT", ModuleImportRequest},
-    RequestPair {u8"MODULE-COMPILED", ModuleCompiledRequest},
-    RequestPair {u8"INCLUDE-TRANSLATE", IncludeTranslateRequest},
+    RequestPair {(const char *) u8"HELLO", nullptr},
+    RequestPair {(const char *) u8"MODULE-REPO", ModuleRepoRequest},
+    RequestPair {(const char *) u8"MODULE-EXPORT", ModuleExportRequest},
+    RequestPair {(const char *) u8"MODULE-IMPORT", ModuleImportRequest},
+    RequestPair {(const char *) u8"MODULE-COMPILED", ModuleCompiledRequest},
+    RequestPair {(const char *) u8"INCLUDE-TRANSLATE", IncludeTranslateRequest},
   };
 }

@@ -135,21 +135,21 @@ void Server::ProcessRequests (void)
 	  std::string msg;

 	  if (err > 0)
-	    msg = u8"error processing '";
+	    msg = (const char *) u8"error processing '";
 	  else if (ix >= Detail::RC_HWM)
-	    msg = u8"unrecognized '";
+	    msg = (const char *) u8"unrecognized '";
 	  else if (IsConnected () && ix == Detail::RC_CONNECT)
-	    msg = u8"already connected '";
+	    msg = (const char *) u8"already connected '";
 	  else if (!IsConnected () && ix != Detail::RC_CONNECT)
-	    msg = u8"not connected '";
+	    msg = (const char *) u8"not connected '";
 	  else
-	    msg = u8"malformed '";
+	    msg = (const char *) u8"malformed '";

 	  read.LexedLine (msg);
-	  msg.append (u8"'");
+	  msg.append ((const char *) u8"'");
 	  if (err > 0)
 	    {
-	      msg.append (u8" ");
+	      msg.append ((const char *) u8" ");
 	      msg.append (strerror (err));
 	    }
 	  resolver->ErrorResponse (this, std::move (msg));
@@ -176,7 +176,7 @@ Resolver *ConnectRequest (Server *s, Resolver *r,
     return nullptr;

   if (words.size () == 3)
-    words.emplace_back (u8"");
+    words.emplace_back ((const char *) u8"");
   unsigned version = ParseUnsigned (words[1]);
   if (version == ~0u)
     return nullptr;
--
2.43.7
EOF
patch -p1 << 'EOF'
From: Lars Gierth <larsg@systemli.org>

This patch backports a small but important part of the upstream commit:

b3f1b9e2aa07 build: Remove INCLUDE_MEMORY [PR117737]

Its original commit message fails to mention that the commit also moves
the `#include <memory>` to an earlier position within system.h,
which is the actual change that we're after in this patch.

Building our GCC 14.3 with host GCC 16, the inclusion order starts to matter,
which is an issue that was also touched upon by the upstream commits:

9970b576b7e4 Include safe-ctype.h after C++ standard headers, to avoid over-poisoning
f6e00226a4ca build: Move sstream include above safe-ctype.h {PR117771]

Error log:

    > gcc -v
    Using built-in specs.
    COLLECT_GCC=gcc
    COLLECT_LTO_WRAPPER=/usr/libexec/gcc/x86_64-redhat-linux/16/lto-wrapper
    OFFLOAD_TARGET_NAMES=nvptx-none:amdgcn-amdhsa
    OFFLOAD_TARGET_DEFAULT=1
    Target: x86_64-redhat-linux
    Configured with: ../configure --enable-bootstrap --enable-languages=c,c++,fortran,objc,obj-c++,ada,go,d,m2,cobol,algol68,lto --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --with-bugurl=https://bugzilla.redhat.com/ --enable-shared --enable-threads=posix --enable-checking=release --enable-multilib --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-gcc-major-version-only --enable-libstdcxx-backtrace --with-libstdcxx-zoneinfo=/usr/share/zoneinfo --with-linker-hash-style=gnu --enable-plugin --enable-initfini-array --with-isl=/builddir/build/BUILD/gcc-16.0.1-build/gcc-16.0.1-20260321/obj-x86_64-redhat-linux/isl-install --enable-offload-targets=nvptx-none,amdgcn-amdhsa --enable-offload-defaulted --without-cuda-driver --enable-gnu-indirect-function --enable-cet --with-tune=generic --with-tls=gnu2 --with-arch_32=i686 --build=x86_64-redhat-linux --with-build-config=bootstrap-lto --enable-link-serialization=1 --disable-libssp
    Thread model: posix
    Supported LTO compression algorithms: zlib zstd
    gcc version 16.0.1 20260321 (Red Hat 16.0.1-0) (GCC)
    > git clean -fdx
    > make defconfig
    > make V=s
    [...]
    make[5]: Entering directory '/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0-initial/gcc'
    g++  -fno-PIE -c  -DIN_GCC_FRONTEND -O2 -I/home/user/w/ow/openwrt/staging_dir/host/include -pipe   -DIN_GCC -DCROSS_DIRECTORY_STRUCTURE   -fno-exceptions -fno-rtti -fasynchronous-unwind-tables -W -Wall -Wno-narrowing -Wwrite-strings -Wcast-qual -Wmissing-format-attribute -Wconditionally-supported -Woverloaded-virtual -pedantic -Wno-long-long -Wno-variadic-macros -Wno-overlength-strings   -DHAVE_CONFIG_H -fno-PIE -I. -Ic -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/c -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../include  -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../libcpp/include -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../libcody -I/home/user/w/ow/openwrt/staging_dir/host/include -I/home/user/w/ow/openwrt/staging_dir/host/include -I/home/user/w/ow/openwrt/staging_dir/host/include  -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../libdecnumber -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../libdecnumber/dpd -I../libdecnumber -I/home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/../libbacktrace   -o c/c-decl.o -MT c/c-decl.o -MMD -MP -MF c/.deps/c-decl.TPo /home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/c/c-decl.cc
    In file included from /usr/include/c++/16/bits/basic_ios.h:40,
                     from /usr/include/c++/16/ios:48,
                     from /usr/include/c++/16/bits/ostream.h:43,
                     from /usr/include/c++/16/bits/unique_ptr.h:42,
                     from /usr/include/c++/16/memory:80,
                     from /home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/system.h:766,
                     from /home/user/w/ow/openwrt/build_dir/toolchain-aarch64_cortex-a53_gcc-14.3.0_musl/gcc-14.3.0/gcc/c/c-decl.cc:30:
    /usr/include/c++/16/bits/locale_facets.h:252:53: error: macro 'toupper' passed 2 arguments, but takes just 1
      252 |       toupper(char_type *__lo, const char_type* __hi) const
          |                                                     ^
    [...]


--- a/gcc/system.h
+++ b/gcc/system.h
@@ -222,6 +222,7 @@ extern int fprintf_unlocked (FILE *, con
 #ifdef INCLUDE_FUNCTIONAL
 # include <functional>
 #endif
+# include <memory>
 # include <cstring>
 # include <initializer_list>
 # include <new>
@@ -758,13 +759,6 @@ private:
 #define LIKELY(x) (__builtin_expect ((x), 1))
 #define UNLIKELY(x) (__builtin_expect ((x), 0))

-/* Some of the headers included by <memory> can use "abort" within a
-   namespace, e.g. "_VSTD::abort();", which fails after we use the
-   preprocessor to redefine "abort" as "fancy_abort" below.  */
-
-#ifdef INCLUDE_MEMORY
-# include <memory>
-#endif

 #ifdef INCLUDE_MUTEX
 # include <mutex>
EOF
	)
	touch "${gcc}_patched"
fi
if [ "${skipGdb}" = "n" ]; then
	extract "${gdbArchive}"
fi
extract "${gmpArchive}"
if [ ! -f "${gmp}_patched" ]; then
	messageB "Patching ${gmp}"
	(
	cd "${gmp}"
patch -p1 << 'EOF'
# HG changeset patch
# User Marc Glisse <marc.glisse@inria.fr>
# Date 1738186682 -3600
# Node ID 8e7bb4ae7a18b1405ea7f9cbcda450b7d920a901
# Parent  e84c5c785bbe8ed8c3620194e50b65adfc2f5d83
Complete function prototype in acinclude.m4 for C23 compatibility

diff -r e84c5c785bbe -r 8e7bb4ae7a18 acinclude.m4
--- a/acinclude.m4	Wed Dec 04 18:26:27 2024 +0100
+++ b/acinclude.m4	Wed Jan 29 22:38:02 2025 +0100
@@ -609,7 +609,7 @@

 #if defined (__GNUC__) && ! defined (__cplusplus)
 typedef unsigned long long t1;typedef t1*t2;
-void g(){}
+void g(int,t1 const*,t1,t2,t1 const*,int){}
 void h(){}
 static __inline__ t1 e(t2 rp,t2 up,int n,t1 v0)
 {t1 c,x,r;int i;if(v0){c=1;for(i=1;i<n;i++){x=up[i];r=x+1;rp[i]=r;}}return c;}
EOF
	autoreconf -vif
	)
	touch "${gmp}_patched"
fi
extract "${islArchive}"
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	extract "${libiconvArchive}"
fi
extract "${mpcArchive}"
extract "${mpfrArchive}"
extract "${newlibArchive}"
if [ ! -f "${pythonArchiveWin32}_extracted" ] && [ "${enableWin32}" = "y" ]; then
	messageB "Extracting ${pythonArchiveWin32}"
	7za x "${pythonArchiveWin32}" "-o${pythonWin32}"
	touch "${pythonArchiveWin32}_extracted"
fi
if [ ! -f "${pythonArchiveWin64}_extracted" ] && [ "${enableWin64}" = "y" ]; then
	messageB "Extracting ${pythonArchiveWin64}"
	7za x "${pythonArchiveWin64}" "-o${pythonWin64}"
	touch "${pythonArchiveWin64}_extracted"
fi
extract "${zlibArchive}"
cd "${top}"

hostTriplet=$("${sources}/${newlib}/config.guess")

buildZlib "${buildNative}" "" "" ""

buildGmp "${buildNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\""

buildMpfr "${buildNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\""

buildMpc "${buildNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\""

buildIsl "${buildNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\""

buildExpat "${buildNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\""

buildBinutils "${buildNative}" "${installNative}" "" "--build=\"${hostTriplet}\" --host=\"${hostTriplet}\"" "${documentationTypes}"

buildGcc "${buildNative}" "${installNative}" "" "--enable-languages=c --without-headers"

if [ "${skipNanoLibraries}" = "n" ]; then
	(
	export PATH="${top}/${installNative}/bin:${PATH-}"

	buildNewlib \
		"-nano" \
		"-Os" \
		"--prefix=\"${top}/${buildNative}/${nanoLibraries}\" \
			--enable-newlib-nano-malloc \
			--enable-lite-exit \
			--enable-newlib-nano-formatted-io" \
		""

	buildGccFinal "-nano" "-Os" "${buildNative}/${nanoLibraries}" ""
	)

	if [ -d "${top}/${buildNative}/${nanoLibraries}" ]; then
		copyNanoLibraries "${top}/${buildNative}/${nanoLibraries}" "${top}/${installNative}"
	fi
fi

buildNewlib \
	"" \
	"-O2" \
	"--prefix=\"${top}/${installNative}\" \
		--docdir=\"${top}/${installNative}/share/doc\" \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--disable-newlib-atexit-dynamic-alloc" \
	"${documentationTypes}"

buildGccFinal "-final" "-O2" "${installNative}" "${documentationTypes}"

if [ "${skipGdb}" = "n" ]; then
	buildGdb \
		"${buildNative}" \
		"${installNative}" \
		"" \
		"--build=\"${hostTriplet}\" --host=\"${hostTriplet}\" --with-python=yes" \
		"${documentationTypes}"
fi

find "${installNative}" -type f -exec chmod a+w {} +
postCleanup "${installNative}" "" "${hostSystem}" ""
if [ "${uname}" = "Darwin" ]; then
	find "${installNative}" -type f -perm +111 -exec strip -ur {} \; || true
else
	find "${installNative}" -type f -executable -exec strip {} \; || true
fi
find "${installNative}" -type f -exec chmod a-w {} +
if [ "${buildDocumentation}" = "y" ]; then
	find "${installNative}/share/doc" -mindepth 2 -name '*.pdf' -exec mv {} "${installNative}/share/doc" \;
fi

messageA "Package"
tagFile="${top}/${buildNative}/package_generated"
if [ ! -f "${tagFile}" ]; then
	maybeDelete "${package}"
	ln -s "${installNative}" "${package}"
	maybeDelete "${packageArchiveNative}"
	if [ "${uname}" = "Darwin" ]; then
		XZ_OPT=${XZ_OPT-"-9e -v"} tar -cJf "${packageArchiveNative}" "${package}"/*
	else
		XZ_OPT=${XZ_OPT-"-9e -v"} tar -cJf "${packageArchiveNative}" --mtime='@0' --numeric-owner --group=0 --owner=0 "${package}"/*
	fi
	maybeDelete "${package}"
	touch "${tagFile}"
fi

if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

buildMingw() {
	(
	triplet="${1}"
	buildFolder="${2}"
	installFolder="${3}"
	pythonFolder="${4}"
	bannerPrefix="${5}"
	packageArchive="${6}"

	flags="-O2 -pipe -Wp,-D_FORTIFY_SOURCE=2 -fno-plt -fstack-protector -fexceptions --param=ssp-buffer-size=4"

	export AR="${triplet}-ar"
	export AS="${triplet}-as"
	export CC="${triplet}-gcc"
	export CC_FOR_BUILD="gcc"
	export CFLAGS="${flags} ${CFLAGS-}"
	export CXX="${triplet}-g++"
	export CXXFLAGS="${flags} ${CXXFLAGS-}"
	export LDFLAGS="-Wl,-O2,--sort-common,--as-needed -fstack-protector -lssp ${LDFLAGS-}"
	export NM="${triplet}-nm"
	export OBJDUMP="${triplet}-objdump"
	export PATH="${top}/${installNative}/bin:${PATH-}"
	export PKG_CONFIG_LIBDIR="/usr/${triplet}/lib/pkgconfig:/usr/${triplet}/share/pkgconfig"
	export PKG_CONFIG_PATH="${PKG_CONFIG_PATH_CUSTOM-}:${PKG_CONFIG_LIBDIR}"
	export RANLIB="${triplet}-ranlib"
	export RC="${triplet}-windres"
	export STRIP="${triplet}-strip"
	export WINDRES="${triplet}-windres"

	messageA "${bannerPrefix}Copy common files"
	mkdir -p "${installFolder}/${target}"
	cp -Rf "${installNative}/${target}/include" "${installFolder}/${target}"
	cp -Rf "${installNative}/${target}/lib" "${installFolder}/${target}"
	mkdir -p "${installFolder}/lib"
	cp -Rf "${installNative}/lib/gcc" "${installFolder}/lib"
	mkdir -p "${installFolder}/share"
	if [ "${buildDocumentation}" = "y" ]; then
		cp -Rf "${installNative}/share/doc" "${installFolder}/share"
	fi
	cp -Rf "${installNative}"/share/gcc-* "${installFolder}/share"

	(
		messageA "${bannerPrefix}${libiconv}"
		tagFile="${top}/${buildFolder}/libiconv_built"
		if [ ! -f "${tagFile}" ]; then
			maybeDelete "${buildFolder}/${libiconv}"
			mkdir -p "${buildFolder}/${libiconv}"
			cd "${buildFolder}/${libiconv}"
			messageB "${bannerPrefix}${libiconv} configure"
			eval "\"${top}/${sources}/${libiconv}/configure\" \
				${quietConfigureOptions} \
				--build=\"${hostTriplet}\" \
				--host=\"${triplet}\" \
				--prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\" \
				--disable-shared \
				--disable-nls"
			messageB "${bannerPrefix}${libiconv} make"
			make "-j${nproc}"
			messageB "${bannerPrefix}${libiconv} make install"
			make install
			touch "${tagFile}"
			cd "${top}"
			if [ "${keepBuildFolders}" = "n" ]; then
				messageB "${bannerPrefix}${libiconv} remove build folder"
				maybeDelete "${top}/${buildFolder}/${libiconv}"
			fi
		fi
	)

	buildZlib \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"-f win32/Makefile.gcc PREFIX=\"${triplet}-\" CFLAGS=\"${CFLAGS}\" LDFLAGS=\"${LDFLAGS}\"" \
		"-f win32/Makefile.gcc \
			BINARY_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/bin\" \
			INCLUDE_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" \
			LIBRARY_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\""

	buildGmp \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\""

	buildMpfr \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\""

	buildMpc \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\""

	buildIsl \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\""

	buildExpat \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\""

	buildBinutils \
		"${buildFolder}" \
		"${installFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\"" \
		""

	buildGcc \
		"${buildFolder}" \
		"${installFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\" \
			--enable-languages=c,c++ \
			--with-headers=yes \
			--with-libiconv-prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\""

	cat > "${buildFolder}/python.sh" <<- EOF
	#!/bin/sh
	shift
	while [ "\${#}" -gt 0 ]; do
		case "\${1}" in
			--prefix|--exec-prefix)
				echo "${top}/${sources}/${pythonFolder}/tools"
				;;
			--includes)
				echo "-D_hypot=hypot -I${top}/${sources}/${pythonFolder}/tools/include"
				;;
			--ldflags)
				echo "-L${top}/${sources}/${pythonFolder}/tools -lpython$(echo "${pythonVersion}" | sed -n 's/^\([^.]\{1,\}\)\.\([^.]\{1,\}\).*$/\1\2/p')"
				;;
		esac
		shift
	done
	EOF
	chmod +x "${buildFolder}/python.sh"

	if [ "${skipGdb}" = "n" ]; then
		buildGdb \
			"${buildFolder}" \
			"${installFolder}" \
			"${bannerPrefix}" \
			"--build=\"${hostTriplet}\" --host=\"${triplet}\" \
				--with-python=\"${top}/${buildFolder}/python.sh\" \
				--program-prefix=\"${target}-\" \
				--program-suffix=-py \
				--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
				--with-libiconv-prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\"" \
			""
		if [ "${keepBuildFolders}" = "y" ]; then
			mv "${buildFolder}/${gdb}" "${buildFolder}/${gdb}-py"
		fi

		buildGdb \
			"${buildFolder}" \
			"${installFolder}" \
			"${bannerPrefix}" \
			"--build=\"${hostTriplet}\" --host=\"${triplet}\" \
				--with-python=no \
				--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
				--with-libiconv-prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\"" \
			""
	fi

	postCleanup "${installFolder}" "${bannerPrefix}" "${triplet}" "- ${libiconv}\n- python-${pythonVersion}\n"
	maybeDelete "${installFolder}/lib/gcc/${target}/${gccVersion}/plugin"
	maybeDelete "${installFolder}/share/info"
	maybeDelete "${installFolder}/share/man"
	find "${installFolder}" -executable ! -type d ! -name '*.exe' ! -name '*.dll' ! -name '*.sh' -exec rm -f {} +
	dlls=$(find "${installFolder}/" -name '*.exe' -exec "${triplet}-objdump" -p {} \; | sed -ne "s/^.*DLL Name: \(.*\)$/\1/p" | sort -u)
	for dll in ${dlls}; do
		path=$(${triplet}-gcc -print-file-name=${dll})
		if [ ! -e "${path}" ]; then
			path="/usr/${triplet}/bin/${dll}"
		fi
		if [ -e "${path}" ]; then
			install -D -m644 "${path}" "${installFolder}/bin/${path##*/}"
		fi
	done
	find "${installFolder}" -name '*.exe' -exec "${STRIP}" {} \;
	find "${installFolder}" -name '*.dll' -exec "${STRIP}" --strip-unneeded {} \;
	sed -i 's/$/\r/' "${installFolder}/info.txt"

	messageA "${bannerPrefix}Package"
	tagFile="${top}/${buildFolder}/package_generated"
	if [ ! -f "${tagFile}" ]; then
		maybeDelete "${package}"
		ln -s "${installFolder}" "${package}"
		maybeDelete "${packageArchive}"
		7za a -mx=9 "${packageArchive}" "${package}"
		maybeDelete "${package}"
		touch "${tagFile}"
	fi
	)
}

if [ "${enableWin32}" = "y" ]; then
	buildMingw \
		"i686-w64-mingw32" \
		"${buildWin32}" \
		"${installWin32}" \
		"${pythonWin32}" \
		"Win32: " \
		"${packageArchiveWin32}"
fi

if [ "${enableWin64}" = "y" ]; then
	buildMingw \
		"x86_64-w64-mingw32" \
		"${buildWin64}" \
		"${installWin64}" \
		"${pythonWin64}" \
		"Win64: " \
		"${packageArchiveWin64}"
fi

fi	# if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

messageA "Done"
