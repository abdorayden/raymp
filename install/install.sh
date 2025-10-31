#!/bin/bash

# /**************************************************************************************/
# /*  Copyright (c) 2025 Ray Den 							*/
# /*  											*/ 
# /*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
# /*  of this software and associated documentation files (the "Software"), to deal 	*/
# /*  in the Software without restriction, including without limitation the rights 	*/
# /*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 	*/
# /*  copies of the Software, and to permit persons to whom the Software is 		*/
# /*  furnished to do so, subject to the following conditions: 				*/
# /*  											*/ 
# /*  The above copyright notice and this permission notice shall be included in 	*/
# /*  all copies or substantial portions of the Software. 				*/
# /*  											*/ 
# /*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 	*/
# /*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
# /*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
# /*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
# /*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
# /*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 	*/
# /*  THE SOFTWARE. 									*/
# /*  											*/ 
# /**************************************************************************************/

INIT_PATH="$HOME/.rmp/.init.lua"
INCLUDE_PATH="-I../src/engine/lua/include -I../src/third_party -O3"

LIB_PATH="-L../src/engine/lua/lib -l:liblua.a -lm"
CC="gcc"

# windows version using mingw
# LIB_PATH="-L../src/engine/lua/lib -l:lua54.dll -lm"
# CC="x86_64-w64-mingw32-gcc"

FLAGS="-shared  -fPIC -Wall -Wextra"

help(){
	echo "HELP:"
	echo "Usage: $0 [command]"
	echo ""
	echo "Commands:"
	echo "	clean : remove all installed shared librarys and lua files from the system files"
	echo "	compile : compile .c files lua libs to shared libs"
	echo "	install : install .so and .lua files to system files"
	echo "		-v : verbose flag"
	echo "NOTE:"
	echo "	install and clean command require root privileges"
	exit 1
}

# check if no command was provided or if help is explicitly requested
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
    help
fi

# check if the user is a root
if [ "$1" = "install" ] || [ "$1" = "clean" ]; then
	if [ "$(id -u)" -ne 0 ]; then
		echo "ERROR: This script must be run as root" >&2
		echo "Try: sudo $0 $*" >&2
		help

	fi
fi

#TODO: create rmp dir to store my libs

LUA_SHARE="/usr/local/share/lua/5.4/rmp"
LUA_LIB="/usr/local/lib/lua/5.4/rmp"

# for lua files
if [ ! -d $LUA_SHARE ]; then
	mkdir -p $LUA_SHARE
fi

# for shared library files
if [ ! -d $LUA_LIB ]; then
	mkdir -p $LUA_LIB
fi

if [[ "$1" == "clean" ]]
then
	echo "[+] cleaning ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi
	rm "$LUA_LIB/rmpaudio.so"
	rm "$LUA_LIB/keyboard.so"
	rm "$LUA_LIB/rsocket.so"
	rm "$LUA_LIB/sleep.so"
	rm "$LUA_LIB/directory.so"
	rm "$LUA_LIB/window.so"

	rm "$LUA_SHARE/rmp.lua"
	rm "$LUA_SHARE/promises.lua"
	rm "$LUA_SHARE/future.lua"
	rm "$LUA_SHARE/util.lua"
	rm "$LUA_SHARE/oop.lua"

elif [[ "$1" == "compile" ]]
then
	echo "[+] compiling ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/rmpaudio.so ../src/engine/core/src/rmpaudio.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/virtualterminalrmp.so ../src/engine/core/src/virtualterminalrmp.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/keyboard.so ../src/engine/core/src/keyboard.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/sleep.so ../src/engine/core/src/sleep.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/platform.so ../src/engine/core/src/platform.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/directory.so ../src/engine/core/src/directory.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/window.so ../src/engine/core/src/window.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		$FLAGS\
		-o ../src/engine/core/lib/rsocket.so ../src/engine/core/src/rsocket.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	$CC \
		-Wall \
		-Wextra \
		-Wunused-variable\
		../main.c\
		-o ../rmp \
		-I ../src/engine \
		$INCLUDE_PATH	\
		../src/engine/runner.c\
		$LIB_PATH

elif [[ "$1" == "install" ]]
then
	echo "[+] Installing ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi
	cp ../src/engine/core/lib/rmpaudio.so $LUA_LIB
	cp ../src/engine/core/lib/keyboard.so $LUA_LIB
	cp ../src/engine/core/lib/sleep.so $LUA_LIB
	cp ../src/engine/core/lib/platform.so $LUA_LIB
	cp ../src/engine/core/lib/directory.so $LUA_LIB
	cp ../src/engine/core/lib/window.so $LUA_LIB
	cp ../src/engine/core/lib/rsocket.so $LUA_LIB
	cp ../src/engine/core/lib/virtualterminalrmp.so $LUA_LIB

	# install the local plugins and themes if the configuration dir not found on home dir
	cp -r ../src/engine/selfrmp $LUA_SHARE

	cp ../src/promises.lua 		$LUA_SHARE
	cp ../src/future.lua 		$LUA_SHARE
	cp ../src/util.lua 		$LUA_SHARE
	cp ../src/oop.lua 		$LUA_SHARE
	cp ../src/engine/core/rmp.lua 	$LUA_SHARE
	# cp ../rmp /bin

	exit 0

	if [ ! -d "$HOME/.rmp" ]; then
		mkdir -p "$HOME/.rmp"
		mkdir -p "$HOME/.rmp/themes"
		mkdir -p "$HOME/.rmp/plugins"
		echo "return {" >> INIT_PATH 
		echo "	sound_cfg = {" >> INIT_PATH 
		echo "		pause = api.KEY_SPACE," >> INIT_PATH 
		echo "		resume = api.KEY_SPACE," >> INIT_PATH 
		echo "		next = api.KEY_N," >> INIT_PATH 
		echo "		prev = api.KEY_P," >> INIT_PATH 
		echo "		vol_up = api.KEY_PLUS," >> INIT_PATH 
		echo "		vol_down = api.KEY_MINUS," >> INIT_PATH 
		echo "		seek_left = api.KEY_LEFT," >> INIT_PATH 
		echo "		seek_right = api.KEY_RIGHT," >> INIT_PATH 
		echo "		speed_up = api.KEY_UP," >> INIT_PATH 
		echo "		speed_down = api.KEY_DOWN," >> INIT_PATH 
		echo "	}," >> INIT_PATH 

		#  TODO: add default theme path 
		echo "	theme = \"theme path\"," >> INIT_PATH 

		# TODO: add default plugins
		echo "	plugins = {" >> INIT_PATH 
		echo "	}," >> INIT_PATH 


		echo "}" >> INIT_PATH 
	fi

else
	echo "[-] there's no subcommand $1"
	help
fi
