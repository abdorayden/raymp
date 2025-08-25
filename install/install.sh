#!/bin/bash

INIT_PATH="$HOME/.rmp/.init.lua"
INCLUDE_PATH="-I../src/engine/lua/include"
LIB_PATH="-L../src/engine/lua/lib -l:liblua.a"
FLAGS="-shared  -fPIC  -Wall -Wextra"

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

# for lua files
if [ ! -d "/usr/local/share/lua/5.4" ]; then
	mkdir -p "/usr/local/share/lua/5.4"
fi

# for shared library files
if [ ! -d "/usr/local/lib/lua/5.4" ]; then
	mkdir -p "/usr/local/lib/lua/5.4"
fi

if [[ "$1" == "clean" ]]
then
	echo "[+] cleaning ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi
	rm /usr/local/lib/lua/5.4/rmpaudio.so
	rm /usr/local/lib/lua/5.4/keyboard.so
	rm /usr/local/lib/lua/5.4/sleep.so
	rm /usr/local/share/lua/5.4/rmp.lua

elif [[ "$1" == "compile" ]]
then
	echo "[+] compiling ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi

	gcc \
		$FLAGS\
		-o ../src/engine/core/lib/rmpaudio.so ../src/engine/core/src/rmpaudio.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	gcc \
		$FLAGS\
		-o ../src/engine/core/lib/keyboard.so ../src/engine/core/src/keyboard.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	gcc \
		$FLAGS\
		-o ../src/engine/core/lib/sleep.so ../src/engine/core/src/sleep.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	gcc \
		$FLAGS\
		-o ../src/engine/core/lib/platform.so ../src/engine/core/src/platform.c \
		$INCLUDE_PATH	\
		$LIB_PATH

	gcc \
		$FLAGS\
		-o ../src/engine/core/lib/directory.so ../src/engine/core/src/directory.c \
		$INCLUDE_PATH	\
		$LIB_PATH

elif [[ "$1" == "install" ]]
then
	echo "[+] Installing ..."
	if [[ "$2" == "-v" ]]
	then
		set -xe
	fi
	cp ../src/engine/core/lib/rmpaudio.so /usr/local/lib/lua/5.4
	cp ../src/engine/core/lib/keyboard.so /usr/local/lib/lua/5.4
	cp ../src/engine/core/lib/sleep.so /usr/local/lib/lua/5.4
	cp ../src/engine/core/lib/platform.so /usr/local/lib/lua/5.4
	cp ../src/engine/core/lib/directory.so /usr/local/lib/lua/5.4
	cp ../src/engine/core/rmp.lua /usr/local/share/lua/5.4

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
