#!/bin/sh

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

BOOST_VERSION="1_45_0"
BOOST_SOURCE_DIR="boost_$BOOST_VERSION"
BOOST_ARCHIVE="$BOOST_SOURCE_DIR.tar.gz"
BOOST_URL="http://sourceforge.net/projects/boost/files/boost/1.45.0/$BOOST_ARCHIVE/download"
BOOST_MD5="739792c98fafb95e7a6b5da23a30062c" # for boost_1_45_0.tar.gz

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

#if [ -f "$BOOST_SOURCE_DIR" ] ; then
    fetch_archive "$BOOST_URL" "$BOOST_ARCHIVE" "$BOOST_MD5"
    extract "$BOOST_ARCHIVE"
#fi

# Add boost coroutine to the linden lab boost build
COROUTINE_TAR=boost-coroutine-2009-04-30.tar.gz
tar xzf "$COROUTINE_TAR"
cd boost-coroutine 
patch -p1 < "../boost-coroutine-linden.patch"
patch -p0 < "../boost-coroutine-linden-2.patch"
patch -p1 < "../boost-coroutine-2009-12-01.patch"

cp -rv boost/coroutine "../$BOOST_SOURCE_DIR/boost"
cd ..

top="$(pwd)"
cd "$BOOST_SOURCE_DIR"
stage="$(pwd)/stage"
BOOST_BJAM_OPTIONS="--with-program_options --with-regex --with-date_time --with-filesystem"

case "$AUTOBUILD_PLATFORM" in
    "windows")
	stage_lib="$stage/lib"
	stage_release="$stage_lib/release"
	stage_debug="$stage/lib/debug"
	mkdir -p "$stage_release"
	mkdir -p "$stage_debug"

	cmd.exe /C bootstrap.bat
	./bjam --toolset=msvc-10.0 $BOOST_BJAM_OPTIONS stage
	mv "$stage_lib/libboost_program_options-vc100-mt.lib" "$stage_release"
	mv "$stage_lib/libboost_regex-vc100-mt.lib" "$stage_release"
	mv "$stage_lib/libboost_date_time-vc100-mt.lib" "$stage_release"
	mv "$stage_lib/libboost_filesystem-vc100-mt.lib" "$stage_release"
	mv "$stage_lib/libboost_system-vc100-mt.lib" "$stage_release"

	mv "$stage_lib/libboost_program_options-vc100-mt-gd.lib" "$stage_debug"
	mv "$stage_lib/libboost_regex-vc100-mt-gd.lib" "$stage_debug"
	mv "$stage_lib/libboost_date_time-vc100-mt-gd.lib" "$stage_debug"
	mv "$stage_lib/libboost_filesystem-vc100-mt-gd.lib" "$stage_debug"
	mv "$stage_lib/libboost_system-vc100-mt-gd.lib" "$stage_debug"
        ;;
    "darwin")
	stage_lib="$stage/lib"
	./bootstrap.sh --prefix=$(pwd)

	./bjam toolset=darwin variant=release $BOOST_BJAM_OPTIONS stage
	stage_release="$stage_lib/release"
	mkdir -p "$stage_release"
	mv "$stage_lib/libboost_program_options.a" "$stage_release"
	mv "$stage_lib/libboost_regex.a" "$stage_release"
	mv "$stage_lib/libboost_date_time.a" "$stage_release"
	mv "$stage_lib/libboost_filesystem.a" "$stage_release"
	mv "$stage_lib/libboost_system.a" "$stage_release"

	./bjam toolset=darwin variant=debug $BOOST_BJAM_OPTIONS stage
	stage_debug="$stage/lib/debug"
	mkdir -p "$stage_debug"
	mv "$stage_lib/libboost_program_options.a" "$stage_debug"
	mv "$stage_lib/libboost_regex.a" "$stage_debug"
	mv "$stage_lib/libboost_date_time.a" "$stage_debug"
	mv "$stage_lib/libboost_filesystem.a" "$stage_debug"
	mv "$stage_lib/libboost_system.a" "$stage_debug"
        ;;
    "linux")
	stage_lib="$stage/lib"
	./bootstrap.sh --prefix=$(pwd)
	./bjam toolset=gcc-4.1 variant=release $BOOST_BJAM_OPTIONS stage
	stage_release="$stage_lib/release"

	mkdir -p "$stage_release"
	mv "$stage_lib/libboost_program_options.a" "$stage_release"
	mv "$stage_lib/libboost_regex.a" "$stage_release"
	mv "$stage_lib/libboost_date_time.a" "$stage_release"
	mv "$stage_lib/libboost_filesystem.a" "$stage_release"
	mv "$stage_lib/libboost_system.a" "$stage_release"

	./bjam toolset=gcc-4.1 variant=debug $BOOST_BJAM_OPTIONS stage
	stage_debug="$stage/lib/debug"
	mkdir -p "$stage_debug"
	mv "$stage_lib/libboost_program_options.a" "$stage_debug"
	mv "$stage_lib/libboost_regex.a" "$stage_debug"
	mv "$stage_lib/libboost_date_time.a" "$stage_debug"
	mv "$stage_lib/libboost_filesystem.a" "$stage_debug"
	mv "$stage_lib/libboost_system.a" "$stage_debug"
        ;;
esac
    
mkdir -p "$stage/include"
cp -R boost "$stage/include"
mkdir -p "$stage/LICENSES"
cp LICENSE_1_0.txt "$stage/LICENSES/"boost.txt

cd "$top"

pass

