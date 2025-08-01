main:
	gcc -o main main.c engine.c -I./lua/include -L./lua/lib -l:liblua.a -lm -ggdb
	#gcc -shared -fPIC -o ./core/lib/rmpaudio.so ./core/src/rmpaudio.c -I./lua/include -L./lua/lib -l:liblua.a

	# sudo cp ./core/rmp.lua /usr/local/lib/lua/5.4/
	# sudo cp ./core/lib/rmpaudio.so /usr/share/lua/5.4
	
	# TODO: handle windows bin
	# x86_64-w64-mingw32-gcc -o main_windows.exe main.c engine.c -I.\lua\include -L.\lua\lib -l:liblua.a -lm -ggdb
	#gcc -o main main.c -I./lua/include -L./lua/lib -l:liblua.a -lm -ggdb
