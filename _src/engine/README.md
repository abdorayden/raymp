# RMP Engine

. this engine will run lua scripts <br>
1. configure ui and designe of the software 
2. controle windows 
3. controle colours
4. add plugins 

- [ ] build standerd library to controle terminal 
- [ ] build hight level library for creating and design boxes and access internet
- [ ] recreate raymp design using lua script as default style 
- [ ] build plugin manager to manage plugins 

# Requirement
## download and link with the source 
- download lua source from offcial web site https://www.lua.org<br>
```console
$curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
$tar zxf lua-5.4.7.tar.gz
$cd lua-5.4.7
$make all test
$gcc -o main main.c -I/path/to/lua_folder/src -L/path/to/lua_folder/src -l:liblua.a -lm
```
## using package manager
```console
$ sudo apt install liblua-<lua version>-dev
$ #and link it using -llua<lua version>
$ #to find lua headers use :
$ find /usr/include -type f -name lua*
$ #or try :
$ locate lua.h
$ gcc -o main main.c -llua5.4
```

this engine will run rmp script's for having wonderfull music player experience<br>
if you see this project is usefull you can [cuntribute](https://github.com/abdorayden/raymp/blob/master/CONTRIBUTIONS.md) it
