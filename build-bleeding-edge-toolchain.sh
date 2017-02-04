#!/bin/sh

#
# file: build-bleeding-edge-toolchain.sh
#
# author: Copyright (C) 2016-2017 Freddie Chopin http://www.freddiechopin.info http://www.distortec.com
#
# This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
# distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

set -e
set -u

binutilsVersion="2.27"
expatVersion="2.2.0"
gccVersion="6.3.0"
gdbVersion="7.12"
gmpVersion="6.1.2"
islVersion="0.16.1"
libiconvVersion="1.14"
mpcVersion="1.0.3"
mpfrVersion="3.1.5"
newlibVersion="2.5.0"
pythonVersion="2.7.13"
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
binutilsArchive="${binutils}.tar.bz2"
expat="expat-${expatVersion}"
expatArchive="${expat}.tar.bz2"
gcc="gcc-${gccVersion}"
gccArchive="${gcc}.tar.bz2"
gdb="gdb-${gdbVersion}"
gdbArchive="${gdb}.tar.xz"
gmp="gmp-${gmpVersion}"
gmpArchive="${gmp}.tar.xz"
isl="isl-${islVersion}"
islArchive="${isl}.tar.bz2"
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
zlibArchive="${zlib}.tar.xz"

pkgversion="bleeding-edge-toolchain"
target="arm-none-eabi"
package="${target}-${gcc}-$(date +'%y%m%d')"
packageArchiveNative="${package}.tar.xz"
packageArchiveWin32="${package}-win32.7z"
packageArchiveWin64="${package}-win64.7z"

bold="$(tput bold)"
normal="$(tput sgr0)"

enableWin32="n"
enableWin64="n"
keepBuildFolders="n"
while [ ${#} -gt 0 ]; do
	case ${1} in
		--enable-win32)
			enableWin32="y"
			;;
		--enable-win64)
			enableWin64="y"
			;;
		--keep-build-folders)
			keepBuildFolders="y"
			;;

		*)
			echo "Usage: $0 [--enable-win32] [--enable-win64] [--keep-build-folders]" >&2
			exit 1
	esac
	shift
done

buildZlib() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local makeOptions="${3}"
	local makeInstallOptions="${4}"
	echo "${bold}********** ${bannerPrefix}${zlib}${normal}"
	cp -R ${sources}/${zlib} ${buildFolder}
	cd ${buildFolder}/${zlib}
	echo "${bold}---------- ${bannerPrefix}${zlib} configure${normal}"
	./configure --static --prefix=${top}/${buildFolder}/${prerequisites}/${zlib}
	echo "${bold}---------- ${bannerPrefix}${zlib} make${normal}"
	eval "make ${makeOptions} -j$(nproc)"
	echo "${bold}---------- ${bannerPrefix}${zlib} make install${normal}"
	eval "make ${makeInstallOptions} install"
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${zlib} remove build folder${normal}"
		rm -rf ${buildFolder}/${zlib}
	fi
	)
}

buildGmp() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${gmp}${normal}"
	mkdir -p ${buildFolder}/${gmp}
	cd ${buildFolder}/${gmp}
	echo "${bold}---------- ${bannerPrefix}${gmp} configure${normal}"
	eval "${top}/${sources}/${gmp}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--enable-cxx \
		--disable-shared \
		--disable-nls"
	echo "${bold}---------- ${bannerPrefix}${gmp} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${gmp} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gmp} remove build folder${normal}"
		rm -rf ${buildFolder}/${gmp}
	fi
	)
}

buildMpfr() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${mpfr}${normal}"
	mkdir -p ${buildFolder}/${mpfr}
	cd ${buildFolder}/${mpfr}
	echo "${bold}---------- ${bannerPrefix}${mpfr} configure${normal}"
	eval "${top}/${sources}/${mpfr}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${mpfr} \
		--disable-shared \
		--disable-nls \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp}"
	echo "${bold}---------- ${bannerPrefix}${mpfr} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${mpfr} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${mpfr} remove build folder${normal}"
		rm -rf ${buildFolder}/${mpfr}
	fi
	)
}

buildMpc() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${mpc}${normal}"
	mkdir -p ${buildFolder}/${mpc}
	cd ${buildFolder}/${mpc}
	echo "${bold}---------- ${bannerPrefix}${mpc} configure${normal}"
	eval "${top}/${sources}/${mpc}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${mpc} \
		--disable-shared \
		--disable-nls \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildFolder}/${prerequisites}/${mpfr}"
	echo "${bold}---------- ${bannerPrefix}${mpc} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${mpc} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${mpc} remove build folder${normal}"
		rm -rf ${buildFolder}/${mpc}
	fi
	)
}

buildIsl() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${isl}${normal}"
	mkdir -p ${buildFolder}/${isl}
	cd ${buildFolder}/${isl}
	echo "${bold}---------- ${bannerPrefix}${isl} configure${normal}"
	eval "${top}/${sources}/${isl}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${isl} \
		--disable-shared \
		--disable-nls \
		--with-gmp-prefix=${top}/${buildFolder}/${prerequisites}/${gmp}"
	echo "${bold}---------- ${bannerPrefix}${isl} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${isl} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${isl} remove build folder${normal}"
		rm -rf ${buildFolder}/${isl}
	fi
	)
}

buildExpat() {
	(
	local buildFolder="${1}"
	local bannerPrefix="${2}"
	local configureOptions="${3}"
	echo "${bold}********** ${bannerPrefix}${expat}${normal}"
	mkdir -p ${buildFolder}/${expat}
	cd ${buildFolder}/${expat}
	echo "${bold}---------- ${bannerPrefix}${expat} configure${normal}"
	eval "${top}/${sources}/${expat}/configure \
		${configureOptions} \
		--prefix=${top}/${buildFolder}/${prerequisites}/${expat} \
		--disable-shared \
		--disable-nls"
	echo "${bold}---------- ${bannerPrefix}${expat} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${expat} make install${normal}"
	make install
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${expat} remove build folder${normal}"
		rm -rf ${buildFolder}/${expat}
	fi
	)
}

buildBinutils() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	local documentations="${5}"
	echo "${bold}********** ${bannerPrefix}${binutils}${normal}"
	mkdir -p ${buildFolder}/${binutils}
	cd ${buildFolder}/${binutils}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${binutils} configure${normal}"
	eval "${top}/${sources}/${binutils}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--disable-nls \
		--enable-interwork \
		--enable-multilib \
		--enable-plugins \
		--with-system-zlib \
		\"--with-pkgversion=${pkgversion}\""
	echo "${bold}---------- ${bannerPrefix}${binutils} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${binutils} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${bannerPrefix}${binutils} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${binutils} remove build folder${normal}"
		rm -rf ${buildFolder}/${binutils}
	fi
	)
}

buildGcc() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	echo "${bold}********** ${bannerPrefix}${gcc}${normal}"
	mkdir -p ${buildFolder}/${gcc}
	cd ${buildFolder}/${gcc}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${gcc} configure${normal}"
	eval "${top}/${sources}/${gcc}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--libexecdir=${top}/${installFolder}/lib \
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
		--with-sysroot=${top}/${installFolder}/${target} \
		--with-system-zlib \
		--with-gmp=${top}/${buildFolder}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildFolder}/${prerequisites}/${mpfr} \
		--with-mpc=${top}/${buildFolder}/${prerequisites}/${mpc} \
		--with-isl=${top}/${buildFolder}/${prerequisites}/${isl} \
		\"--with-pkgversion=${pkgversion}\" \
		--with-multilib-list=armv6-m,armv7-m,armv7e-m,armv7-r"
	echo "${bold}---------- ${bannerPrefix}${gcc} make all-gcc${normal}"
	make -j$(nproc) all-gcc
	echo "${bold}---------- ${bannerPrefix}${gcc} make install-gcc${normal}"
	make install-gcc
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gcc} remove build folder${normal}"
		rm -rf ${buildFolder}/${gcc}
	fi
	)
}

buildNewlib() {
	(
	local suffix="${1}"
	local optimization="${2}"
	local configureOptions="${3}"
	local documentations="${4}"
	echo "${bold}********** ${newlib}${suffix}${normal}"
	mkdir -p ${buildNative}/${newlib}${suffix}
	cd ${buildNative}/${newlib}${suffix}
	export PATH="${top}/${installNative}/bin:${PATH-}"
	export CFLAGS_FOR_TARGET="-g ${optimization} -ffunction-sections -fdata-sections ${CFLAGS_FOR_TARGET-}"
	echo "${bold}---------- ${newlib}${suffix} configure${normal}"
	eval "${top}/${sources}/${newlib}/configure \
		${configureOptions} \
		--target=${target} \
		--disable-newlib-supplied-syscalls \
		--enable-newlib-reent-small \
		--disable-newlib-fvwrite-in-streamio \
		--disable-newlib-fseek-optimization \
		--disable-newlib-wide-orient \
		--disable-newlib-unbuf-stream-opt \
		--enable-newlib-global-atexit \
		--disable-nls"
	echo "${bold}---------- ${newlib}${suffix} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${newlib}${suffix} make install${normal}"
	make install
	for documentation in ${documentations}; do
		cd ${target}/newlib/libc
		echo "${bold}---------- ${newlib}${suffix} libc make install-${documentation}${normal}"
		make install-${documentation}
		cd ../../..
		cd ${target}/newlib/libm
		echo "${bold}---------- ${newlib}${suffix} libm make install-${documentation}${normal}"
		make install-${documentation}
		cd ../../..
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${newlib}${suffix} remove build folder${normal}"
		rm -rf ${buildNative}/${newlib}${suffix}
	fi
	)
}

buildGccFinal() {
	(
	local suffix="${1}"
	local optimization="${2}"
	local installFolder="${3}"
	local documentations="${4}"
	echo "${bold}********** ${gcc}${suffix}${normal}"
	mkdir -p ${buildNative}/${gcc}${suffix}
	cd ${buildNative}/${gcc}${suffix}
	export CPPFLAGS="-I${top}/${buildNative}/${prerequisites}/${zlib}/include ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildNative}/${prerequisites}/${zlib}/lib ${LDFLAGS-}"
	export CFLAGS_FOR_TARGET="-g ${optimization} -ffunction-sections -fdata-sections -fno-exceptions ${CFLAGS_FOR_TARGET-}"
	export CXXFLAGS_FOR_TARGET="-g ${optimization} -ffunction-sections -fdata-sections -fno-exceptions ${CXXFLAGS_FOR_TARGET-}"
	echo "${bold}---------- ${gcc}${suffix} configure${normal}"
	${top}/${sources}/${gcc}/configure \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--libexecdir=${top}/${installFolder}/lib \
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
		--with-sysroot=${top}/${installFolder}/${target} \
		--with-system-zlib \
		--with-gmp=${top}/${buildNative}/${prerequisites}/${gmp} \
		--with-mpfr=${top}/${buildNative}/${prerequisites}/${mpfr} \
		--with-mpc=${top}/${buildNative}/${prerequisites}/${mpc} \
		--with-isl=${top}/${buildNative}/${prerequisites}/${isl} \
		"--with-pkgversion=${pkgversion}" \
		--with-multilib-list=armv6-m,armv7-m,armv7e-m,armv7-r
	echo "${bold}---------- ${gcc}${suffix} make${normal}"
	make -j$(nproc) INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
	echo "${bold}---------- ${gcc}${suffix} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${gcc}${suffix} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${gcc}${suffix} remove build folder${normal}"
		rm -rf ${buildNative}/${gcc}${suffix}
	fi
	)
}

copyNanoLibraries() {
	local source="${1}"
	local destination="${2}"
	echo "${bold}********** \"nano\" libraries copy${normal}"
	local multilibs="$(${destination}/bin/${target}-gcc -print-multi-lib)"
	local sourcePrefix="${source}/${target}/lib"
	local destinationPrefix="${destination}/${target}/lib"
	local sourceDirectory
	local destinationDirectory
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
		rm -rf ${top}/${buildNative}/${nanoLibraries}
	fi
}

buildGdb() {
	(
	local buildFolder="${1}"
	local installFolder="${2}"
	local bannerPrefix="${3}"
	local configureOptions="${4}"
	local documentations="${5}"
	echo "${bold}********** ${bannerPrefix}${gdb}${normal}"
	mkdir -p ${buildFolder}/${gdb}
	cd ${buildFolder}/${gdb}
	export CPPFLAGS="-I${top}/${buildFolder}/${prerequisites}/${zlib}/include ${CPPFLAGS-}"
	export LDFLAGS="-L${top}/${buildFolder}/${prerequisites}/${zlib}/lib ${LDFLAGS-}"
	echo "${bold}---------- ${bannerPrefix}${gdb} configure${normal}"
	eval "${top}/${sources}/${gdb}/configure \
		${configureOptions} \
		--target=${target} \
		--prefix=${top}/${installFolder} \
		--docdir=${top}/${installFolder}/share/doc \
		--disable-nls \
		--disable-sim \
		--with-libexpat \
		--with-lzma=no \
		--with-system-gdbinit=${top}/${installFolder}/${target}/lib/gdbinit \
		--with-system-zlib \
		--with-libexpat-prefix=${top}/${buildFolder}/${prerequisites}/${expat} \
		\"--with-gdb-datadir='\\\${prefix}'/${target}/share/gdb\" \
		\"--with-pkgversion=${pkgversion}\""
	echo "${bold}---------- ${bannerPrefix}${gdb} make${normal}"
	make -j$(nproc)
	echo "${bold}---------- ${bannerPrefix}${gdb} make install${normal}"
	make install
	for documentation in ${documentations}; do
		echo "${bold}---------- ${bannerPrefix}${gdb} make install-${documentation}${normal}"
		make install-${documentation}
	done
	cd ${top}
	if [ "${keepBuildFolders}" = "n" ]; then
		echo "${bold}---------- ${bannerPrefix}${gdb} remove build folder${normal}"
		rm -rf ${buildFolder}/${gdb}
	fi
	)
}

postCleanup() {
	local installFolder="${1}"
	local bannerPrefix="${2}"
	local hostSystem="${3}"
	local extraComponents="${4}"
	echo "${bold}********** ${bannerPrefix}Post-cleanup${normal}"
	rm -rf ${installFolder}/include
	find ${installFolder} -name '*.la' -exec rm -rf {} +
	cat > ${installFolder}/info.txt <<- EOF
	${pkgversion}
	build date: $(date +'%Y-%m-%d')
	build system: $(uname -srvmo)
	host system: ${hostSystem}
	target system: ${target}
	compiler: ${CC-gcc} $(${CC-gcc} --version | grep -o '[0-9]\.[0-9]\.[0-9]')

	Toolchain components:
	- ${gcc} + multilib patch
	- ${newlib}
	- ${binutils}
	- ${gdb}
	$(echo -en "- ${expat}\n- ${gmp}\n- ${isl}\n- ${mpc}\n- ${mpfr}\n- ${zlib}\n${extraComponents}" | sort)

	This package and info about it can be found on Freddie Chopin's website:
	http://www.freddiechopin.info/
	EOF
	cp ${0} ${installFolder}
}

echo "${bold}********** Cleanup${normal}"
rm -rf ${buildNative}
rm -rf ${installNative}
mkdir -p ${buildNative}
mkdir -p ${installNative}
rm -rf ${buildWin32}
rm -rf ${installWin32}
if [ "${enableWin32}" = "y" ]; then
	mkdir -p ${buildWin32}
	mkdir -p ${installWin32}
fi
rm -rf ${buildWin64}
rm -rf ${installWin64}
if [ "${enableWin64}" = "y" ]; then
	mkdir -p ${buildWin64}
	mkdir -p ${installWin64}
fi
mkdir -p ${sources}
find ${sources} -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
find ${sources} -mindepth 1 -maxdepth 1 -type f ! -name "${binutilsArchive}" \
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

echo "${bold}********** Download${normal}"
mkdir -p ${sources}
cd ${sources}
download() {
	if [ ! -e ${1} ]; then
		echo "${bold}---------- Downloading ${1}${normal}"
		curl -L -o ${1} -C - ${2}
	fi
}
download ${binutilsArchive} ftp://ftp.gnu.org/gnu/binutils/${binutilsArchive}
download ${expatArchive} https://sourceforge.net/projects/expat/files/expat/${expatVersion}/${expatArchive}
download ${gccArchive} ftp://ftp.gnu.org/gnu/gcc/${gcc}/${gccArchive}
download ${gdbArchive} ftp://ftp.gnu.org/gnu/gdb/${gdbArchive}
download ${gmpArchive} ftp://ftp.gnu.org/gnu/gmp/${gmpArchive}
download ${islArchive} ftp://gcc.gnu.org/pub/gcc/infrastructure/${islArchive}
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	download ${libiconvArchive} ftp://ftp.gnu.org/pub/gnu/libiconv/${libiconvArchive}
fi
download ${mpcArchive} ftp://ftp.gnu.org/gnu/mpc/${mpcArchive}
download ${mpfrArchive} ftp://ftp.gnu.org/gnu/mpfr/${mpfrArchive}
download ${newlibArchive} ftp://sourceware.org/pub/newlib/${newlibArchive}
if [ "${enableWin32}" = "y" ]; then
	download ${pythonArchiveWin32} https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin32}
fi
if [ "${enableWin64}" = "y" ]; then
	download ${pythonArchiveWin64} https://www.python.org/ftp/python/${pythonVersion}/${pythonArchiveWin64}
fi
download ${zlibArchive} https://sourceforge.net/projects/libpng/files/zlib/${zlibVersion}/${zlibArchive}
cd ${top}

echo "${bold}********** Extract${normal}"
cd ${sources}
echo "${bold}---------- Extracting ${binutilsArchive}${normal}"
tar -xf ${binutilsArchive}
echo "${bold}---------- Extracting ${expatArchive}${normal}"
tar -xf ${expatArchive}
echo "${bold}---------- Extracting ${gccArchive}${normal}"
tar -xf ${gccArchive}
echo "${bold}---------- Extracting ${gdbArchive}${normal}"
tar -xf ${gdbArchive}
echo "${bold}---------- Extracting ${gmpArchive}${normal}"
tar -xf ${gmpArchive}
echo "${bold}---------- Extracting ${islArchive}${normal}"
tar -xf ${islArchive}
if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then
	echo "${bold}---------- Extracting ${libiconvArchive}${normal}"
	tar -xf ${libiconvArchive}
fi
echo "${bold}---------- Extracting ${mpcArchive}${normal}"
tar -xf ${mpcArchive}
echo "${bold}---------- Extracting ${mpfrArchive}${normal}"
tar -xf ${mpfrArchive}
echo "${bold}---------- Extracting ${newlibArchive}${normal}"
tar -xf ${newlibArchive}
if [ "${enableWin32}" = "y" ]; then
	echo "${bold}---------- Extracting ${pythonArchiveWin32}${normal}"
	7za x ${pythonArchiveWin32} -o${pythonWin32}
fi
if [ "${enableWin64}" = "y" ]; then
	echo "${bold}---------- Extracting ${pythonArchiveWin64}${normal}"
	7za x ${pythonArchiveWin64} -o${pythonWin64}
fi
echo "${bold}---------- Extracting ${zlibArchive}${normal}"
tar -xf ${zlibArchive}
cd ${top}

echo "${bold}********** Patch${normal}"
cd ${sources}/${gcc}
patch -p1 << 'EOF'
diff -ruN gcc-6.3.0-original/gcc/config/arm/t-baremetal gcc-6.3.0/gcc/config/arm/t-baremetal
--- gcc-6.3.0-original/gcc/config/arm/t-baremetal	1970-01-01 01:00:00.000000000 +0100
+++ gcc-6.3.0/gcc/config/arm/t-baremetal	2016-12-21 13:45:16.570939667 +0100
@@ -0,0 +1,143 @@
+# A set of predefined MULTILIB which can be used for different ARM targets.
+# Via the configure option --with-multilib-list, user can customize the
+# final MULTILIB implementation.
+
+comma := ,
+
+with_multilib_list := $(subst $(comma), ,$(with_multilib_list))
+
+MULTILIB_OPTIONS   = mthumb/marm
+MULTILIB_DIRNAMES  = thumb arm
+MULTILIB_OPTIONS  += march=armv6s-m/march=armv7-m/march=armv7e-m/march=armv7/march=armv8-m.base/march=armv8-m.main
+MULTILIB_DIRNAMES += armv6-m armv7-m armv7e-m armv7-ar armv8-m.base armv8-m.main
+MULTILIB_OPTIONS  += mlittle-endian/mbig-endian
+MULTILIB_DIRNAMES += le/be
+MULTILIB_OPTIONS  += mfloat-abi=softfp/mfloat-abi=hard
+MULTILIB_DIRNAMES += softfp fpu
+MULTILIB_OPTIONS  += mfpu=fpv5-sp-d16/mfpu=fpv5-d16/mfpu=fpv4-sp-d16/mfpu=vfpv3-d16
+MULTILIB_DIRNAMES += fpv5-sp-d16 fpv5-d16 fpv4-sp-d16 vfpv3-d16
+
+MULTILIB_MATCHES   = march?armv6s-m=mcpu?cortex-m0
+MULTILIB_MATCHES  += march?armv6s-m=mcpu?cortex-m0.small-multiply
+MULTILIB_MATCHES  += march?armv6s-m=mcpu?cortex-m0plus
+MULTILIB_MATCHES  += march?armv6s-m=mcpu?cortex-m0plus.small-multiply
+MULTILIB_MATCHES  += march?armv6s-m=mcpu?cortex-m1
+MULTILIB_MATCHES  += march?armv6s-m=mcpu?cortex-m1.small-multiply
+MULTILIB_MATCHES  += march?armv6s-m=march?armv6-m
+MULTILIB_MATCHES  += march?armv7-m=mcpu?cortex-m3
+MULTILIB_MATCHES  += march?armv7e-m=mcpu?cortex-m4
+MULTILIB_MATCHES  += march?armv7e-m=mcpu?cortex-m7
+MULTILIB_MATCHES  += march?armv7e-m=mcpu?marvell-pj4
+MULTILIB_MATCHES  += march?armv7=march?armv7-r
+MULTILIB_MATCHES  += march?armv7=march?armv7-a
+MULTILIB_MATCHES  += march?armv7=march?armv8-a
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-r4
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-r4f
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-r5
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-r7
+MULTILIB_MATCHES  += march?armv7=mcpu?generic-armv7-a
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a5
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a7
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a8
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a9
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a12
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a15
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a17
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a15.cortex-a7
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a17.cortex-a7
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a53
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a57
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a72
+MULTILIB_MATCHES  += march?armv7=mcpu?exynos-m1
+MULTILIB_MATCHES  += march?armv7=mcpu?xgene1
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a57.cortex-a53
+MULTILIB_MATCHES  += march?armv7=mcpu?cortex-a72.cortex-a53
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv3
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv3-fp16
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv3-d16-fp16
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv3xd
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv3xd-fp16
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv4
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?vfpv4-d16
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?neon
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?neon-fp16
+MULTILIB_MATCHES  += mfpu?vfpv3-d16=mfpu?neon-vfpv4
+
+MULTILIB_EXCEPTIONS =
+MULTILIB_REUSE =
+
+MULTILIB_REQUIRED  = mthumb
+MULTILIB_REQUIRED += marm
+MULTILIB_REQUIRED += mfloat-abi=hard
+
+MULTILIB_OSDIRNAMES  = mthumb=!thumb
+MULTILIB_OSDIRNAMES += marm=!arm
+MULTILIB_OSDIRNAMES += mfloat-abi.hard=!fpu
+
+ifneq (,$(findstring armv6-m,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv6s-m
+MULTILIB_OSDIRNAMES += mthumb/march.armv6s-m=!armv6-m
+endif
+
+ifneq (,$(findstring armv8-m.base,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.base
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.base=!armv8-m.base
+endif
+
+ifneq (,$(findstring armv7-m,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv7-m
+MULTILIB_OSDIRNAMES += mthumb/march.armv7-m=!armv7-m
+endif
+
+ifneq (,$(findstring armv7e-m,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=softfp/mfpu=fpv4-sp-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=hard/mfpu=fpv4-sp-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=softfp/mfpu=fpv5-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=hard/mfpu=fpv5-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=softfp/mfpu=fpv5-sp-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7e-m/mfloat-abi=hard/mfpu=fpv5-sp-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m=!armv7e-m
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.hard/mfpu.fpv4-sp-d16=!armv7e-m/fpu
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.softfp/mfpu.fpv4-sp-d16=!armv7e-m/softfp
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.hard/mfpu.fpv5-d16=!armv7e-m/fpu/fpv5-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.softfp/mfpu.fpv5-d16=!armv7e-m/softfp/fpv5-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.hard/mfpu.fpv5-sp-d16=!armv7e-m/fpu/fpv5-sp-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv7e-m/mfloat-abi.softfp/mfpu.fpv5-sp-d16=!armv7e-m/softfp/fpv5-sp-d16
+endif
+
+ifneq (,$(findstring armv8-m.main,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.main
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.main/mfloat-abi=softfp/mfpu=fpv5-d16
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.main/mfloat-abi=hard/mfpu=fpv5-d16
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.main/mfloat-abi=softfp/mfpu=fpv5-sp-d16
+MULTILIB_REQUIRED   += mthumb/march=armv8-m.main/mfloat-abi=hard/mfpu=fpv5-sp-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.main=!armv8-m.main
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.main/mfloat-abi.hard/mfpu.fpv5-d16=!armv8-m.main/fpu/fpv5-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.main/mfloat-abi.softfp/mfpu.fpv5-d16=!armv8-m.main/softfp/fpv5-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.main/mfloat-abi.hard/mfpu.fpv5-sp-d16=!armv8-m.main/fpu/fpv5-sp-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv8-m.main/mfloat-abi.softfp/mfpu.fpv5-sp-d16=!armv8-m.main/softfp/fpv5-sp-d16
+endif
+
+ifneq (,$(filter armv7 armv7-r armv7-a,$(with_multilib_list)))
+MULTILIB_REQUIRED   += mthumb/march=armv7
+MULTILIB_REQUIRED   += mthumb/march=armv7/mfloat-abi=softfp/mfpu=vfpv3-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7/mfloat-abi=hard/mfpu=vfpv3-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7/mbig-endian
+MULTILIB_REQUIRED   += mthumb/march=armv7/mbig-endian/mfloat-abi=softfp/mfpu=vfpv3-d16
+MULTILIB_REQUIRED   += mthumb/march=armv7/mbig-endian/mfloat-abi=hard/mfpu=vfpv3-d16
+MULTILIB_OSDIRNAMES += mthumb/march.armv7=!armv7-ar/le/thumb
+MULTILIB_OSDIRNAMES += mthumb/march.armv7/mfloat-abi.hard/mfpu.vfpv3-d16=!armv7-ar/le/thumb/fpu
+MULTILIB_OSDIRNAMES += mthumb/march.armv7/mfloat-abi.softfp/mfpu.vfpv3-d16=!armv7-ar/le/thumb/softfp
+MULTILIB_OSDIRNAMES += mthumb/march.armv7/mbig-endian=!armv7-ar/be/thumb
+MULTILIB_OSDIRNAMES += mthumb/march.armv7/mbig-endian/mfloat-abi.hard/mfpu.vfpv3-d16=!armv7-ar/be/thumb/fpu
+MULTILIB_OSDIRNAMES += mthumb/march.armv7/mbig-endian/mfloat-abi.softfp/mfpu.vfpv3-d16=!armv7-ar/be/thumb/softfp
+MULTILIB_REUSE      += mthumb/march.armv7=marm/march.armv7
+MULTILIB_REUSE      += mthumb/march.armv7/mfloat-abi.softfp/mfpu.vfpv3-d16=marm/march.armv7/mfloat-abi.softfp/mfpu.vfpv3-d16
+MULTILIB_REUSE      += mthumb/march.armv7/mfloat-abi.hard/mfpu.vfpv3-d16=marm/march.armv7/mfloat-abi.hard/mfpu.vfpv3-d16
+MULTILIB_REUSE      += mthumb/march.armv7/mbig-endian=marm/march.armv7/mbig-endian
+MULTILIB_REUSE      += mthumb/march.armv7/mbig-endian/mfloat-abi.softfp/mfpu.vfpv3-d16=marm/march.armv7/mbig-endian/mfloat-abi.softfp/mfpu.vfpv3-d16
+MULTILIB_REUSE      += mthumb/march.armv7/mbig-endian/mfloat-abi.hard/mfpu.vfpv3-d16=marm/march.armv7/mbig-endian/mfloat-abi.hard/mfpu.vfpv3-d16
+
+MULTILIB_MATCHES    += mbig-endian=mbe
+endif
diff -ruN gcc-6.3.0-original/gcc/config.gcc gcc-6.3.0/gcc/config.gcc
--- gcc-6.3.0-original/gcc/config.gcc	2016-11-07 22:38:43.000000000 +0100
+++ gcc-6.3.0/gcc/config.gcc	2016-12-21 13:45:16.570939667 +0100
@@ -1119,7 +1119,7 @@
 	case ${target} in
 	arm*-*-eabi*)
 	  tm_file="$tm_file newlib-stdint.h"
-	  tmake_file="${tmake_file} arm/t-bpabi"
+	  tmake_file="${tmake_file} arm/t-bpabi arm/t-baremetal"
 	  use_gcc_stdint=wrap
 	  ;;
 	arm*-*-rtems*)
@@ -3803,42 +3803,6 @@
 			exit 1
 		fi
 
-		# Add extra multilibs
-		if test "x$with_multilib_list" != x; then
-			arm_multilibs=`echo $with_multilib_list | sed -e 's/,/ /g'`
-			for arm_multilib in ${arm_multilibs}; do
-				case ${arm_multilib} in
-				aprofile)
-				# Note that arm/t-aprofile is a
-				# stand-alone make file fragment to be
-				# used only with itself.  We do not
-				# specifically use the
-				# TM_MULTILIB_OPTION framework because
-				# this shorthand is more
-				# pragmatic. Additionally it is only
-				# designed to work without any
-				# with-cpu, with-arch with-mode
-				# with-fpu or with-float options.
-					if test "x$with_arch" != x \
-					    || test "x$with_cpu" != x \
-					    || test "x$with_float" != x \
-					    || test "x$with_fpu" != x \
-					    || test "x$with_mode" != x ; then
-					    echo "Error: You cannot use any of --with-arch/cpu/fpu/float/mode with --with-multilib-list=aprofile" 1>&2
-					    exit 1
-					fi
-					tmake_file="${tmake_file} arm/t-aprofile"
-					break
-					;;
-				default)
-					;;
-				*)
-					echo "Error: --with-multilib-list=${with_multilib_list} not supported." 1>&2
-					exit 1
-					;;
-				esac
-			done
-		fi
 		;;
 
 	fr*-*-*linux*)
diff -ruN gcc-6.3.0-original/gcc/configure gcc-6.3.0/gcc/configure
--- gcc-6.3.0-original/gcc/configure	2016-12-11 17:23:04.000000000 +0100
+++ gcc-6.3.0/gcc/configure	2016-12-21 13:45:16.574273078 +0100
@@ -767,6 +767,7 @@
 LN_S
 AWK
 SET_MAKE
+with_multilib_list
 accel_dir_suffix
 real_target_noncanonical
 enable_as_accelerator
diff -ruN gcc-6.3.0-original/gcc/configure.ac gcc-6.3.0/gcc/configure.ac
--- gcc-6.3.0-original/gcc/configure.ac	2016-12-11 17:23:04.000000000 +0100
+++ gcc-6.3.0/gcc/configure.ac	2016-12-21 13:45:16.574273078 +0100
@@ -988,6 +988,7 @@
 [AS_HELP_STRING([--with-multilib-list], [select multilibs (AArch64, SH and x86-64 only)])],
 :,
 with_multilib_list=default)
+AC_SUBST(with_multilib_list)
 
 # -------------------------
 # Checks for other programs
diff -ruN gcc-6.3.0-original/gcc/Makefile.in gcc-6.3.0/gcc/Makefile.in
--- gcc-6.3.0-original/gcc/Makefile.in	2016-11-22 18:33:07.000000000 +0100
+++ gcc-6.3.0/gcc/Makefile.in	2016-12-21 13:45:16.574273078 +0100
@@ -546,6 +546,7 @@
 lang_specs_files=@lang_specs_files@
 lang_tree_files=@lang_tree_files@
 target_cpu_default=@target_cpu_default@
+with_multilib_list=@with_multilib_list@
 OBJC_BOEHM_GC=@objc_boehm_gc@
 extra_modes_file=@extra_modes_file@
 extra_opt_files=@extra_opt_files@
EOF
cd ${top}

buildZlib ${buildNative} "" "" ""

buildGmp ${buildNative} "" ""

buildMpfr ${buildNative} "" ""

buildMpc ${buildNative} "" ""

buildIsl ${buildNative} "" ""

buildExpat ${buildNative} "" ""

buildBinutils ${buildNative} ${installNative} "" "" "html pdf"

buildGcc ${buildNative} ${installNative} "" "--enable-languages=c --without-headers"

(
export PATH="${top}/${installNative}/bin:${PATH-}"

buildNewlib \
	"-nano" \
	"-Os" \
	"--prefix=${top}/${buildNative}/${nanoLibraries} \
		--enable-newlib-nano-malloc \
		--enable-lite-exit \
		--enable-newlib-nano-formatted-io" \
	""

buildGccFinal "-nano" "-Os" "${buildNative}/${nanoLibraries}" ""
)

copyNanoLibraries "${top}/${buildNative}/${nanoLibraries}" "${top}/${installNative}"

buildNewlib \
	"" \
	"-O2" \
	"--prefix=${top}/${installNative} \
		--docdir=${top}/${installNative}/share/doc \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--disable-newlib-atexit-dynamic-alloc" \
	"html pdf"

buildGccFinal "-final" "-O2" "${installNative}" "html pdf"

buildGdb ${buildNative} ${installNative} "" "--with-python=yes" "html pdf"

postCleanup ${installNative} "" "$(uname -mo)" ""
find ${installNative} -type f -executable -exec strip {} \; || true
find ${installNative}/share/doc -mindepth 2 -name '*.pdf' -exec mv {} ${installNative}/share/doc \;

echo "${bold}********** Package${normal}"
rm -rf ${package}
ln -s ${installNative} ${package}
rm -rf ${packageArchiveNative}
XZ_OPT="-9e -T 0 -v" tar -cJf ${packageArchiveNative} --group=0 --owner=0 $(find ${package}/ -mindepth 1 -maxdepth 1)
rm -rf ${package}

if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

buildMingw() {
	(
	local triplet="${1}"
	local flags="${2}"
	local buildFolder="${3}"
	local installFolder="${4}"
	local pythonFolder="${5}"
	local bannerPrefix="${6}"
	local packageArchive="${7}"

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

	mkdir -p ${installFolder}/${target}
	cp -R ${installNative}/${target}/include ${installFolder}/${target}/include
	cp -R ${installNative}/${target}/lib ${installFolder}/${target}/lib
	mkdir -p ${installFolder}/lib
	cp -R ${installNative}/lib/gcc ${installFolder}/lib/gcc
	mkdir -p ${installFolder}/share
	cp -R ${installNative}/share/doc ${installFolder}/share/doc
	cp -R ${installNative}/share/${gcc} ${installFolder}/share/${gcc}

	(
		echo "${bold}********** ${bannerPrefix}${libiconv}${normal}"
		mkdir -p ${buildFolder}/${libiconv}
		cd ${buildFolder}/${libiconv}
		echo "${bold}---------- ${bannerPrefix}${libiconv} configure${normal}"
		${top}/${sources}/${libiconv}/configure \
			--host=${triplet} \
			--prefix=${top}/${buildFolder}/${prerequisites}/${libiconv} \
			--disable-shared \
			--disable-nls
		echo "${bold}---------- ${bannerPrefix}${libiconv} make${normal}"
		make -j$(nproc)
		echo "${bold}---------- ${bannerPrefix}${libiconv} make install${normal}"
		make install
		cd ${top}
		if [ "${keepBuildFolders}" = "n" ]; then
			echo "${bold}---------- ${bannerPrefix}${libiconv} remove build folder${normal}"
			rm -rf ${top}/${buildFolder}/${libiconv}
		fi
	)

	buildZlib \
		${buildFolder} \
		${bannerPrefix} \
		"-f win32/Makefile.gcc PREFIX=\"${triplet}-\" CFLAGS=\"${CFLAGS}\"" \
		"-f win32/Makefile.gcc \
			BINARY_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/bin\" \
			INCLUDE_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/include\" \
			LIBRARY_PATH=\"${top}/${buildFolder}/${prerequisites}/${zlib}/lib\""

	buildGmp \
		${buildFolder} \
		${bannerPrefix} \
		"--host=${triplet}"

	buildMpfr \
		${buildFolder} \
		${bannerPrefix} \
		"--host=${triplet}"

	buildMpc \
		${buildFolder} \
		${bannerPrefix} \
		"--host=${triplet}"

	buildIsl \
		${buildFolder} \
		${bannerPrefix} \
		"--host=${triplet}"

	buildExpat \
		${buildFolder} \
		${bannerPrefix} \
		"--host=${triplet}"

	buildBinutils \
		${buildFolder} \
		${installFolder} \
		${bannerPrefix} \
		"--host=${triplet}" \
		""

	buildGcc \
		${buildFolder} \
		${installFolder} \
		${bannerPrefix} \
		"--host=${triplet} \
			--enable-languages=c,c++ \
			--with-headers=yes \
			--with-libiconv-prefix=${top}/${buildFolder}/${prerequisites}/${libiconv}"

	cat > ${buildFolder}/python.sh <<- END
	#!/bin/sh
	shift
	while [ \${#} -gt 0 ]; do
		case \${1} in
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
	END
	chmod +x ${buildFolder}/python.sh

	buildGdb \
		${buildFolder} \
		${installFolder} \
		${bannerPrefix} \
		"--host=${triplet} \
			--with-python=${top}/${buildFolder}/python.sh \
			--program-prefix=${target}- \
			--program-suffix=-py \
			--with-libiconv-prefix=${top}/${buildFolder}/${prerequisites}/${libiconv}" \
		""
	if [ "${keepBuildFolders}" = "y" ]; then
		mv ${buildFolder}/${gdb} ${buildFolder}/${gdb}-py
	fi

	buildGdb \
		${buildFolder} \
		${installFolder} \
		${bannerPrefix} \
		"--host=${triplet} \
			--with-python=no \
			--with-libiconv-prefix=${top}/${buildFolder}/${prerequisites}/${libiconv}" \
		""

	postCleanup ${installFolder} ${bannerPrefix} ${triplet} "- ${libiconv}\n- python-${pythonVersion}\n"
	rm -rf ${installFolder}/lib/gcc/${target}/${gccVersion}/plugin
	rm -rf ${installFolder}/share/info ${installFolder}/share/man
	find ${installFolder} -executable ! -type d ! -name '*.exe' ! -name '*.dll' ! -name '*.sh' -exec rm -f {} +
	dlls="$(find ${installFolder}/ -name '*.exe' -exec ${triplet}-objdump -p {} \; | sed -ne "s/^.*DLL Name: \(.*\)$/\1/p" | sort | uniq)"
	for dll in ${dlls}; do
		cp /usr/${triplet}/bin/${dll} ${installFolder}/bin/ || true
	done
	find ${installFolder} -name '*.exe' -exec ${STRIP} {} \;
	find ${installFolder} -name '*.dll' -exec ${STRIP} --strip-unneeded {} \;
	sed -i 's/$/\r/' ${installFolder}/info.txt

	echo "${bold}********** ${bannerPrefix}Package${normal}"
	rm -rf ${package}
	ln -s ${installFolder} ${package}
	rm -rf ${packageArchive}
	7za a -l -mx=9 ${packageArchive} ${package}
	rm -rf ${package}
	)
}

if [ "${enableWin32}" = "y" ]; then
	buildMingw \
		"i686-w64-mingw32" \
		"-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4" \
		${buildWin32} \
		${installWin32} \
		${pythonWin32} \
		"Win32: " \
		${packageArchiveWin32}
fi

if [ "${enableWin64}" = "y" ]; then
	buildMingw \
		"x86_64-w64-mingw32" \
		"-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4" \
		${buildWin64} \
		${installWin64} \
		${pythonWin64} \
		"Win64: " \
		${packageArchiveWin64}
fi

fi	# if [ "${enableWin32}" = "y" ] || [ "${enableWin64}" = "y" ]; then

echo "${bold}********** Done${normal}"
