#!/bin/sh
# shellcheck disable=SC2030,SC2031

#
# file: build-bleeding-edge-toolchain.sh
#
# author: Copyright (C) 2016-2020 Freddie Chopin http://www.freddiechopin.info http://www.distortec.com
#
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
# distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
#

set -e
set -u

binutilsVersion="2.34"
expatVersion="2.2.9"
gccVersion="9.3.0"
gdbVersion="9.1"
gmpVersion="6.2.0"
islVersion="0.22"
libiconvVersion="1.16"
mpcVersion="1.1.0"
mpfrVersion="4.0.2"
newlibVersion="3.3.0"
pythonVersion="2.7.17"
zlibVersion="1.2.11"

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

pkgversion="bleeding-edge-toolchain"
target="arm-none-eabi"
package="${target}-${gcc}-$(date +'%y%m%d')"
packageArchiveNative="${package}.tar.xz"
packageArchiveWin32="${package}-win32.7z"
packageArchiveWin64="${package}-win64.7z"

bold="$(tput bold)"
normal="$(tput sgr0)"

if [ "$(uname)" = "Darwin" ]; then
	nproc="$(sysctl -n hw.ncpu)"
	hostSystem="$(uname -sm)"
else
	nproc="$(nproc)"
	hostSystem="$(uname -mo)"
fi

enableWin32="n"
enableWin64="n"
keepBuildFolders="n"
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
		--skip-nano-libraries)
			skipNanoLibraries="y"
			;;
		--quiet)
			quiet="y"
			;;
		*)
			echo "Usage: ${0} [--enable-win32] [--enable-win64] [--keep-build-folders] [--resume] [--skip-documentation] [--skip-nano-libraries] [--quiet]" >&2
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
	echo "${bold}********** ${bannerPrefix}${zlib}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${zlib}"
		cp -R "${sources}/${zlib}" "${buildFolder}"
		cd "${buildFolder}/${zlib}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${zlib} configure${normal}"
		./configure --static --prefix="${top}/${buildFolder}/${prerequisites}/${zlib}"
		echo "${bold}---------- ${bannerPrefix}${zlib} make${normal}"
		eval "make ${makeOptions} \"-j${nproc}\""
		echo "${bold}---------- ${bannerPrefix}${zlib} make install${normal}"
		eval "make ${makeInstallOptions} install"
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${zlib} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${gmp}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gmp}"
		mkdir -p "${buildFolder}/${gmp}"
		cd "${buildFolder}/${gmp}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${gmp} configure${normal}"
		eval "\"${top}/${sources}/${gmp}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
			--enable-cxx \
			--disable-shared \
			--disable-nls"
		echo "${bold}---------- ${bannerPrefix}${gmp} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${gmp} make install${normal}"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${gmp} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${mpfr}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${mpfr}"
		mkdir -p "${buildFolder}/${mpfr}"
		cd "${buildFolder}/${mpfr}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${mpfr} configure${normal}"
		eval "\"${top}/${sources}/${mpfr}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\" \
			--disable-shared \
			--disable-nls \
			--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\""
		echo "${bold}---------- ${bannerPrefix}${mpfr} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${mpfr} make install${normal}"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${mpfr} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${mpc}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${mpc}"
		mkdir -p "${buildFolder}/${mpc}"
		cd "${buildFolder}/${mpc}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${mpc} configure${normal}"
		eval "\"${top}/${sources}/${mpc}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${mpc}\" \
			--disable-shared \
			--disable-nls \
			--with-gmp=\"${top}/${buildFolder}/${prerequisites}/${gmp}\" \
			--with-mpfr=\"${top}/${buildFolder}/${prerequisites}/${mpfr}\""
		echo "${bold}---------- ${bannerPrefix}${mpc} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${mpc} make install${normal}"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${mpc} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${isl}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${isl}"
		mkdir -p "${buildFolder}/${isl}"
		cd "${buildFolder}/${isl}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${isl} configure${normal}"
		eval "\"${top}/${sources}/${isl}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${isl}\" \
			--disable-shared \
			--disable-nls \
			--with-gmp-prefix=\"${top}/${buildFolder}/${prerequisites}/${gmp}\""
		echo "${bold}---------- ${bannerPrefix}${isl} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${isl} make install${normal}"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${isl} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${expat}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${expat}"
		mkdir -p "${buildFolder}/${expat}"
		cd "${buildFolder}/${expat}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${expat} configure${normal}"
		eval "\"${top}/${sources}/${expat}/configure\" \
			${quietConfigureOptions} \
			${configureOptions} \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${expat}\" \
			--disable-shared \
			--disable-nls"
		echo "${bold}---------- ${bannerPrefix}${expat} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${expat} make install${normal}"
		make install
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${expat} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${binutils}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${binutils}"
		mkdir -p "${buildFolder}/${binutils}"
		cd "${buildFolder}/${binutils}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${binutils} configure${normal}"
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
		echo "${bold}---------- ${bannerPrefix}${binutils} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${binutils} make install${normal}"
		make install
		for documentation in ${documentations}; do
			echo "${bold}---------- ${bannerPrefix}${binutils} make install-${documentation}${normal}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${binutils} remove build folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${gcc}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gcc}"
		mkdir -p "${buildFolder}/${gcc}"
		cd "${buildFolder}/${gcc}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${gcc} configure${normal}"
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
		echo "${bold}---------- ${bannerPrefix}${gcc} make all-gcc${normal}"
		make "-j${nproc}" all-gcc
		echo "${bold}---------- ${bannerPrefix}${gcc} make install-gcc${normal}"
		make install-gcc
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${gcc} remove build folder${normal}"
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
	echo "${bold}********** ${newlib}${suffix}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildNative}/${newlib}${suffix}"
		mkdir -p "${buildNative}/${newlib}${suffix}"
		cd "${buildNative}/${newlib}${suffix}"
		export CPPFLAGS="${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="${BASE_LDFLAGS-} ${LDFLAGS-}"
		export PATH="${top}/${installNative}/bin:${PATH-}"
		export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
		echo "${bold}---------- ${newlib}${suffix} configure${normal}"
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
		echo "${bold}---------- ${newlib}${suffix} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${newlib}${suffix} make install${normal}"
		make install
		for documentation in ${documentations}; do
			cd "${target}/newlib/libc"
			echo "${bold}---------- ${newlib}${suffix} libc make install-${documentation}${normal}"
			make "install-${documentation}"
			cd ../../..
			cd "${target}/newlib/libm"
			echo "${bold}---------- ${newlib}${suffix} libm make install-${documentation}${normal}"
			make "install-${documentation}"
			cd ../../..
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${newlib}${suffix} remove build folder${normal}"
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
	echo "${bold}********** ${gcc}${suffix}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildNative}/${gcc}${suffix}"
		mkdir -p "${buildNative}/${gcc}${suffix}"
		cd "${buildNative}/${gcc}${suffix}"
		export CPPFLAGS="-I\"${top}/${buildNative}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildNative}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		export CFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CFLAGS_FOR_TARGET-} ${CFLAGS_FOR_TARGET-}"
		export CXXFLAGS_FOR_TARGET="-g ${optimization} ${BASE_CXXFLAGS_FOR_TARGET-} ${CXXFLAGS_FOR_TARGET-}"
		echo "${bold}---------- ${gcc}${suffix} configure${normal}"
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
		echo "${bold}---------- ${gcc}${suffix} make${normal}"
		make "-j${nproc}" INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
		echo "${bold}---------- ${gcc}${suffix} make install${normal}"
		make install
		for documentation in ${documentations}; do
			echo "${bold}---------- ${gcc}${suffix} make install-${documentation}${normal}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${gcc}${suffix} remove build folder${normal}"
			maybeDelete "${buildNative}/${gcc}${suffix}"
		fi
	fi
	)
}

copyNanoLibraries() {
	(
	source="${1}"
	destination="${2}"
	echo "${bold}********** \"nano\" libraries copy${normal}"
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

	mkdir -p "${destination}/arm-none-eabi/include/newlib-nano"
	cp "${source}/arm-none-eabi/include/newlib.h" "${destination}/arm-none-eabi/include/newlib-nano"

	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- \"nano\" libraries remove install folder${normal}"
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
	echo "${bold}********** ${bannerPrefix}${gdb}${normal}"
	if [ ! -f "${tagFileBase}_built" ]; then
		maybeDelete "${buildFolder}/${gdb}"
		mkdir -p "${buildFolder}/${gdb}"
		cd "${buildFolder}/${gdb}"
		export CPPFLAGS="-I\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" ${BASE_CPPFLAGS-} ${CPPFLAGS-}"
		export LDFLAGS="-L\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\" ${BASE_LDFLAGS-} ${LDFLAGS-}"
		echo "${bold}---------- ${bannerPrefix}${gdb} configure${normal}"
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
		echo "${bold}---------- ${bannerPrefix}${gdb} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${gdb} make install${normal}"
		make install
		for documentation in ${documentations}; do
			echo "${bold}---------- ${bannerPrefix}${gdb} make install-${documentation}${normal}"
			make "install-${documentation}"
		done
		touch "${tagFileBase}_built"
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${gdb} remove build folder${normal}"
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
	if [ "$(uname)" = "Darwin" ]; then
		buildSystem="$(uname -srvm)"
	else
		buildSystem="$(uname -srvmo)"
	fi
	echo "${bold}********** ${bannerPrefix}Post-cleanup${normal}"
	maybeDelete "${installFolder}/include"
	find "${installFolder}" -name '*.la' -exec rm -rf {} +
	cat > "${installFolder}/info.txt" <<- EOF
	${pkgversion}
	build date: $(date +'%Y-%m-%d')
	build system: ${buildSystem}
	host system: ${hostSystem}
	target system: ${target}
	compiler: ${CC-gcc} $(${CC-gcc} --version | grep -o '[0-9]\.[0-9]\.[0-9]')

	Toolchain components:
	- ${gcc}
	- ${newlib}
	- ${binutils}
	- ${gdb}
	$(printf -- "- %s\n- %s\n- %s\n- %s\n- %s\n- %s\n%s" "${expat}" "${gmp}" "${isl}" "${mpc}" "${mpfr}" "${zlib}" "${extraComponents}" | sort)

	This package and info about it can be found on Freddie Chopin's website:
	http://www.freddiechopin.info/
	EOF
	cp "${0}" "${installFolder}"
	)
}

if [ "${resume}" = "y" ]; then
	echo "${bold}********** Resuming last build${normal}"
else
	echo "${bold}********** Cleanup${normal}"
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

echo "${bold}********** Download${normal}"
mkdir -p "${sources}"
cd "${sources}"
download() {
	ret=0
	if [ ! -f "${1}_downloaded" ]; then
		echo "${bold}---------- Downloading ${1}${normal}"
		curl -L -o "${1}" -C - --connect-timeout 30 -Y 1024 -y 30 "${2}" || ret="${?}"
		if [ "${ret}" -eq 33 ]; then
			echo 'This happens if the file is complete, continuing...'
		elif [ "${ret}" -ne 0 ]; then
			exit "${ret}"
		fi
		touch "${1}_downloaded"
	fi
}
download "${binutilsArchive}" "https://ftp.gnu.org/gnu/binutils/${binutilsArchive}"
download "${expatArchive}" "https://github.com/libexpat/libexpat/releases/download/$(echo "R_${expatVersion}" | sed 's/\./_/g')/${expatArchive}"
if [ "${gccVersion#*-}" = "${gccVersion}" ]; then
	download "${gccArchive}" "https://ftp.gnu.org/gnu/gcc/${gcc}/${gccArchive}"
else
	download "${gccArchive}" "https://gcc.gnu.org/pub/gcc/snapshots/${gccVersion}/${gccArchive}"
fi
download "${gdbArchive}" "https://ftp.gnu.org/gnu/gdb/${gdbArchive}"
download "${gmpArchive}" "https://ftp.gnu.org/gnu/gmp/${gmpArchive}"
download "${islArchive}" "http://isl.gforge.inria.fr/${islArchive}"
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	download "${libiconvArchive}" "https://ftp.gnu.org/pub/gnu/libiconv/${libiconvArchive}"
fi
download "${mpcArchive}" "https://ftp.gnu.org/gnu/mpc/${mpcArchive}"
download "${mpfrArchive}" "https://ftp.gnu.org/gnu/mpfr/${mpfrArchive}"
download "${newlibArchive}" "https://sourceware.org/pub/newlib/${newlibArchive}"
if [ "${enableWin32}" = "y" ]; then
	download "${pythonArchiveWin32}" "https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin32}"
fi
if [ "${enableWin64}" = "y" ]; then
	download "${pythonArchiveWin64}" "https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin64}"
fi
download "${zlibArchive}" "https://www.zlib.net/fossils/${zlibArchive}"
cd "${top}"

echo "${bold}********** Extract${normal}"
cd "${sources}"
extract() {
	if [ ! -f "${1}_extracted" ]; then
		echo "${bold}---------- Extracting ${1}${normal}"
		tar -xf "${1}"
		touch "${1}_extracted"
	fi
}
extract "${binutilsArchive}"
extract "${expatArchive}"
extract "${gccArchive}"
extract "${gdbArchive}"
extract "${gmpArchive}"
extract "${islArchive}"
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	extract "${libiconvArchive}"
fi
extract "${mpcArchive}"
extract "${mpfrArchive}"
extract "${newlibArchive}"
if [ ! -f "${pythonArchiveWin32}_extracted" ] && [ "${enableWin32}" = "y" ]; then
	echo "${bold}---------- Extracting ${pythonArchiveWin32}${normal}"
	7za x "${pythonArchiveWin32}" "-o${pythonWin32}"
	touch "${pythonArchiveWin32}_extracted"
fi
if [ ! -f "${pythonArchiveWin64}_extracted" ] && [ "${enableWin64}" = "y" ]; then
	echo "${bold}---------- Extracting ${pythonArchiveWin64}${normal}"
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

buildGdb \
	"${buildNative}" \
	"${installNative}" \
	"" \
	"--build=\"${hostTriplet}\" --host=\"${hostTriplet}\" --with-python=yes" \
	"${documentationTypes}"

find "${installNative}" -type f -exec chmod a+w {} +
postCleanup "${installNative}" "" "${hostSystem}" ""
if [ "$(uname)" = "Darwin" ]; then
	find "${installNative}" -type f -perm +111 -exec strip -ur {} \; || true
else
	find "${installNative}" -type f -executable -exec strip {} \; || true
fi
find "${installNative}" -type f -exec chmod a-w {} +
if [ "${buildDocumentation}" = "y" ]; then
	find "${installNative}/share/doc" -mindepth 2 -name '*.pdf' -exec mv {} "${installNative}/share/doc" \;
fi

echo "${bold}********** Package${normal}"
maybeDelete "${package}"
ln -s "${installNative}" "${package}"
maybeDelete "${packageArchiveNative}"
if [ "$(uname)" = "Darwin" ]; then
	XZ_OPT=${XZ_OPT-"-9e -v"} tar -cJf "${packageArchiveNative}" "$(find "${package}/" -mindepth 1 -maxdepth 1)"
else
	XZ_OPT=${XZ_OPT-"-9e -v"} tar -cJf "${packageArchiveNative}" --mtime='@0' --numeric-owner --group=0 --owner=0 "$(find "${package}/" -mindepth 1 -maxdepth 1)"
fi
maybeDelete "${package}"

if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

buildMingw() {
	(
	triplet="${1}"
	flags="${2}"
	buildFolder="${3}"
	installFolder="${4}"
	pythonFolder="${5}"
	bannerPrefix="${6}"
	packageArchive="${7}"

	export AR="${triplet}-ar"
	export AS="${triplet}-as"
	export CC="${triplet}-gcc"
	export CC_FOR_BUILD="gcc"
	export CFLAGS="${flags} ${CFLAGS-}"
	export CXX="${triplet}-g++"
	export CXXFLAGS="${flags} ${CXXFLAGS-}"
	export NM="${triplet}-nm"
	export OBJDUMP="${triplet}-objdump"
	export PATH="${top}/${installNative}/bin:${PATH-}"
	export RANLIB="${triplet}-ranlib"
	export RC="${triplet}-windres"
	export STRIP="${triplet}-strip"
	export WINDRES="${triplet}-windres"

	mkdir -p "${installFolder}/${target}"
	cp -R "${installNative}/${target}/include" "${installFolder}/${target}/include"
	cp -R "${installNative}/${target}/lib" "${installFolder}/${target}/lib"
	mkdir -p "${installFolder}/lib"
	cp -R "${installNative}/lib/gcc" "${installFolder}/lib/gcc"
	mkdir -p "${installFolder}/share"
	if [ "${buildDocumentation}" = "y" ]; then
		cp -R "${installNative}/share/doc" "${installFolder}/share/doc"
	fi
	cp -R "${installNative}"/share/gcc-* "${installFolder}/share/"

	(
		echo "${bold}********** ${bannerPrefix}${libiconv}${normal}"
		mkdir -p "${buildFolder}/${libiconv}"
		cd "${buildFolder}/${libiconv}"
		echo "${bold}---------- ${bannerPrefix}${libiconv} configure${normal}"
		eval "\"${top}/${sources}/${libiconv}/configure\" \
			${quietConfigureOptions} \
			--build=\"${hostTriplet}\" \
			--host=\"${triplet}\" \
			--prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\" \
			--disable-shared \
			--disable-nls"
		echo "${bold}---------- ${bannerPrefix}${libiconv} make${normal}"
		make "-j${nproc}"
		echo "${bold}---------- ${bannerPrefix}${libiconv} make install${normal}"
		make install
		cd "${top}"
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${libiconv} remove build folder${normal}"
			maybeDelete "${top}/${buildFolder}/${libiconv}"
		fi
	)

	buildZlib \
		"${buildFolder}" \
		"${bannerPrefix}" \
		"-f win32/Makefile.gcc PREFIX=\"${triplet}-\" CFLAGS=\"${CFLAGS}\"" \
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

	buildGdb \
		"${buildFolder}" \
		"${installFolder}" \
		"${bannerPrefix}" \
		"--build=\"${hostTriplet}\" --host=\"${triplet}\" \
			--with-python=\"${top}/${buildFolder}/python.sh\" \
			--program-prefix=\"${target}-\" \
			--program-suffix=-py \
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
			--with-libiconv-prefix=\"${top}/${buildFolder}/${prerequisites}/${libiconv}\"" \
		""

	postCleanup "${installFolder}" "${bannerPrefix}" "${triplet}" "- ${libiconv}\n- python-${pythonVersion}\n"
	maybeDelete "${installFolder}/lib/gcc/${target}/${gccVersion}/plugin"
	maybeDelete "${installFolder}/share/info"
	maybeDelete "${installFolder}/share/man"
	find "${installFolder}" -executable ! -type d ! -name '*.exe' ! -name '*.dll' ! -name '*.sh' -exec rm -f {} +
	dlls=$(find "${installFolder}/" -name '*.exe' -exec "${triplet}-objdump" -p {} \; | sed -ne "s/^.*DLL Name: \(.*\)$/\1/p" | sort | uniq)
	for dll in ${dlls}; do
		cp "/usr/${triplet}/bin/${dll}" "${installFolder}/bin/" || true
	done
	find "${installFolder}" -name '*.exe' -exec "${STRIP}" {} \;
	find "${installFolder}" -name '*.dll' -exec "${STRIP}" --strip-unneeded {} \;
	sed -i 's/$/\r/' "${installFolder}/info.txt"

	echo "${bold}********** ${bannerPrefix}Package${normal}"
	maybeDelete "${package}"
	ln -s "${installFolder}" "${package}"
	maybeDelete "${packageArchive}"
	7za a -l -mx=9 "${packageArchive}" "${package}"
	maybeDelete "${package}"
	)
}

if [ "${enableWin32}" = "y" ]; then
	buildMingw \
		"i686-w64-mingw32" \
		"-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4" \
		"${buildWin32}" \
		"${installWin32}" \
		"${pythonWin32}" \
		"Win32: " \
		"${packageArchiveWin32}"
fi

if [ "${enableWin64}" = "y" ]; then
	buildMingw \
		"x86_64-w64-mingw32" \
		"-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4" \
		"${buildWin64}" \
		"${installWin64}" \
		"${pythonWin64}" \
		"Win64: " \
		"${packageArchiveWin64}"
fi

fi	# if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

echo "${bold}********** Done${normal}"
