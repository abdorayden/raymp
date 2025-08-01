#!/bin/bash

# check if the user is a root
if [ "$(id -u)" -ne 0 ]; then
	echo "ERROR: This script must be run as root" >&2
	echo "Try: sudo $0 $*" >&2
	exit 1
fi

# for lua files
if [ ! -d "/usr/local/share/lua/5.4" ]; then
	mkdir -p "/usr/local/share/lua/5.4"
fi

# for shared library files
if [ ! -d "/usr/local/lib/lua/5.4" ]; then
	mkdir -p "/usr/local/lib/lua/5.4"
fi

if [[ $1 == "clean" ]]
then
	rm /usr/local/lib/lua/5.4/rmpaudio.so
	rm /usr/local/lib/lua/5.4/keyboard.so
	rm /usr/local/lib/lua/5.4/sleep.so
	rm /usr/local/share/lua/5.4/rmp.lua
fi

echo "[+] compiling ..."

set -xe

gcc -shared -fPIC -o ../src/engine/core/lib/rmpaudio.so ../src/engine/core/src/rmpaudio.c -I../src/engine/lua/include -L../src/engine/lua/lib -l:liblua.a

gcc -shared -fPIC -o ../src/engine/core/lib/keyboard.so ../src/engine/core/src/keyboard.c -I../src/engine/lua/include -L../src/engine/lua/lib -l:liblua.a

gcc -shared -fPIC -o ../src/engine/core/lib/sleep.so ../src/engine/core/src/sleep.c -I../src/engine/lua/include -L../src/engine/lua/lib -l:liblua.a

echo "[+] Installing"

cp ../src/engine/core/lib/rmpaudio.so /usr/local/lib/lua/5.4
cp ../src/engine/core/lib/keyboard.so /usr/local/lib/lua/5.4
cp ../src/engine/core/lib/sleep.so /usr/local/lib/lua/5.4
cp ../src/engine/core/rmp.lua /usr/local/share/lua/5.4
