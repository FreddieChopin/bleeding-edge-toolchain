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

binutilsVersion="2.42"
expatVersion="2.6.2"
gccVersion="12.3.0"
gdbVersion="14.2"
gmpVersion="6.3.0"
islVersion="0.25"
libiconvVersion="1.17"
mpcVersion="1.2.1"
mpfrVersion="4.1.1"
newlibVersion="4.2.0.20211231"
pythonVersion="2.7.18"
zlibVersion="1.2.13"

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
mpcArchive="${mpc}.tar.gz"
mpfr="mpfr-${mpfrVersion}"
mpfrArchive="${mpfr}.tar.xz"
newlib="newlib-${newlibVersion}"
newlibArchive="${newlib}.tar.gz"
pythonWin32="python-${pythonVersion}"
pythonArchiveWin32="${pythonWin32}.msi"
pythonWin64="python-${pythonVersion}.amd64"
pythonArchiveWin64="${pythonWin64}.msi"
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
			--with-mpfr=yes \
			--with-libmpfr-prefix=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\" \
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
	download "${pythonArchiveWin32}" "https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin32}"
fi
if [ "${enableWin64}" = "y" ]; then
	download "${pythonArchiveWin64}" "https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin64}"
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
if [ "${skipGdb}" = "n" ]; then
	extract "${gdbArchive}"

	if [ ! -f "${gdb}_patched" ]; then
		messageB "Patching ${gdb}"
		(
		cd "${gdb}"
patch -p1 << 'EOF'
From 7bd836d5d90353a2de192fd4711a20b4520246b7 Mon Sep 17 00:00:00 2001
From: Simon Marchi <simon.marchi@polymtl.ca>
Date: Tue, 10 Jan 2023 00:07:25 -0500
Subject: [PATCH] gdb/doc: fix install-html with Texinfo 7

Starting with Texinfo 7 (this commit [1]), the output directory for the
HTML doc format is gdb/doc/gdb_html, rather than gdb/doc/gdb previously.
This breaks the install-html target, which expects the HTML doc to be in
gdb/doc/gdb:

    $ make install-html MAKEINFO=makeinfo DESTDIR=/tmp/install
    make[1]: Entering directory '/home/simark/build/binutils-gdb/gdb'
    make[2]: Entering directory '/home/simark/build/binutils-gdb/gdb/doc'
    makeinfo  -DHAVE_MAKEINFO_CLICK --html  -I /home/simark/src/binutils-gdb/gdb/doc/../../readline/readline/doc -I /home/simark/src/binutils-gdb/gdb/doc/../mi -I /home/simark/src/binutils-gdb/gdb/doc /home/simark/src/binutils-gdb/gdb/doc/gdb.texinfo
    makeinfo  -DHAVE_MAKEINFO_CLICK --html  -I /home/simark/src/binutils-gdb/gdb/doc /home/simark/src/binutils-gdb/gdb/doc/stabs.texinfo
    makeinfo  -DHAVE_MAKEINFO_CLICK --html  -I /home/simark/src/binutils-gdb/gdb/doc /home/simark/src/binutils-gdb/gdb/doc/annotate.texinfo
    test -z "/usr/local/share/doc/gdb" || /bin/sh /home/simark/src/binutils-gdb/gdb/doc/../../mkinstalldirs "/tmp/install/usr/local/share/doc/gdb"
     /usr/bin/install -c -m 644 '/home/simark/src/binutils-gdb/gdb/doc/gdb' '/tmp/install/usr/local/share/doc/gdb/gdb'
    /usr/bin/install: cannot stat '/home/simark/src/binutils-gdb/gdb/doc/gdb': No such file or directory
     /usr/bin/install -c -m 644 '/home/simark/src/binutils-gdb/gdb/doc/stabs' '/tmp/install/usr/local/share/doc/gdb/stabs'
    /usr/bin/install: cannot stat '/home/simark/src/binutils-gdb/gdb/doc/stabs': No such file or directory
     /usr/bin/install -c -m 644 '/home/simark/src/binutils-gdb/gdb/doc/annotate' '/tmp/install/usr/local/share/doc/gdb/annotate'
    /usr/bin/install: cannot stat '/home/simark/src/binutils-gdb/gdb/doc/annotate': No such file or directory
    make[2]: *** [Makefile:278: install-html] Error 1
    make[2]: Leaving directory '/home/simark/build/binutils-gdb/gdb/doc'
    make[1]: *** [Makefile:2240: subdir_do] Error 1
    make[1]: Leaving directory '/home/simark/build/binutils-gdb/gdb'
    make: *** [Makefile:2006: install-html] Error 2

Fix this by adding -o switches to the HTML targets, to force the output
directories.

[1] https://git.savannah.gnu.org/cgit/texinfo.git/commit/?id=a868421baf9c44227c43490687f8d6b8d6c95414

Change-Id: Ie147dc7b4a52eb2348005b8dc006a41b0784621f
---
 gdb/doc/Makefile.in | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/gdb/doc/Makefile.in b/gdb/doc/Makefile.in
index d1012bee98c..5d40aa229b2 100644
--- a/gdb/doc/Makefile.in
+++ b/gdb/doc/Makefile.in
@@ -564,7 +564,10 @@ gdb.mm: $(GDB_DOC_FILES) links2roff
 # GDB MANUAL: HTML file

 gdb/index.html: ${GDB_DOC_FILES}
-	$(MAKEHTML) $(MAKEHTMLFLAGS) $(READLINE_TEXI_INCFLAG) -I ${GDBMI_DIR} -I $(srcdir) $(srcdir)/gdb.texinfo
+	$(MAKEHTML) $(MAKEHTMLFLAGS) \
+		-o gdb \
+		$(READLINE_TEXI_INCFLAG) -I ${GDBMI_DIR} -I $(srcdir) \
+		$(srcdir)/gdb.texinfo

 stabs.info: $(STABS_DOC_FILES)
 	$(MAKEINFO_CMD) -I $(srcdir) -o stabs.info $(srcdir)/stabs.texinfo
@@ -572,7 +575,10 @@ stabs.info: $(STABS_DOC_FILES)
 # STABS DOCUMENTATION: HTML file

 stabs/index.html: $(STABS_DOC_FILES)
-	$(MAKEHTML) $(MAKEHTMLFLAGS) -I $(srcdir) $(srcdir)/stabs.texinfo
+	$(MAKEHTML) $(MAKEHTMLFLAGS) \
+		-o stabs \
+		-I $(srcdir) \
+		$(srcdir)/stabs.texinfo

 # Clean these up before each run.  Avoids a catch 22 with not being
 # able to re-generate these files (to fix a corruption) because these
@@ -614,7 +620,10 @@ annotate.info: $(ANNOTATE_DOC_FILES)
 	$(MAKEINFO_CMD) -I $(srcdir) -o annotate.info $(srcdir)/annotate.texinfo

 annotate/index.html: $(ANNOTATE_DOC_FILES)
-	$(MAKEHTML) $(MAKEHTMLFLAGS) -I $(srcdir) $(srcdir)/annotate.texinfo
+	$(MAKEHTML) $(MAKEHTMLFLAGS) \
+		-o annotate \
+		-I $(srcdir) \
+		$(srcdir)/annotate.texinfo

 # Man pages
 gdb.1: $(GDB_DOC_FILES)
--
2.34.5
EOF
		)
		touch "${gdb}_patched"
	fi

fi
extract "${gmpArchive}"
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
				echo "${top}/${sources}/${pythonFolder}"
				;;
			--includes)
				echo "-D_hypot=hypot -I${top}/${sources}/${pythonFolder}"
				;;
			--ldflags)
				echo "-L${top}/${sources}/${pythonFolder} -lpython$(echo "${pythonVersion}" | sed -n 's/^\([^.]\{1,\}\)\.\([^.]\{1,\}\).*$/\1\2/p')"
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
				--with-libgmp-prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
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
				--with-libgmp-prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
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
		7za a -l -mx=9 "${packageArchive}" "${package}"
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
