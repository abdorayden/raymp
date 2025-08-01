// for testing lua scripts

// download lua source from offcial web site https://www.lua.org
// curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
//tar zxf lua-5.4.7.tar.gz
//cd lua-5.4.7
//make all test
// -I/path/to/lua_folder/src -L/path/to/lua_folder/src -l:liblua.a -lm


// or you can download it using
// sudo apt install liblua-<lua version>-dev
// and link it using -llua<lua version>
// to find lua headers use :
// find /usr/include -type f -name lua*
// or try :

#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>
#include <stdio.h>
#include <stdbool.h>

// lua documentation book https://www.lua.org/pil/24.2.3.html

typedef enum {
	INTEGER = 1,
	STRING,
	TABLE,
	BOOLEAN,
	NUMBER, // it's fucking float
	NONEORNIL,
	NIL,
	FUNCTION,
	THREAD,
	USERDATA,
	YIELDABLE,
}Lua_Type;

typedef struct {
	Lua_Type type;
	void* data;
}Lua_Return_Data;

Lua_Return_Data read_function_from_lua(lua_State* luaObj , const char* function)
{
	// get global function here
	lua_getglobal(luaObj , function);
	if(lua_pcall(luaObj , 0 , 1 , 0) != LUA_OK)
	{
		fprintf(stderr , "error calling function %s , check if function exist" , function);
		fprintf(stderr , "error : %s" , lua_tostring(luaObj , -1));
		return (Lua_Return_Data){0};
	}

	// return last data from function because it's a stack
	if(lua_istable(luaObj , -1)){
		lua_pushstring(luaObj , "window_title");
		lua_gettable(luaObj , -2);
		printf("Table : %s\n" , lua_tostring(luaObj , -1));
		lua_pop(luaObj , 1);
		lua_pushstring(luaObj , "window_id");
		lua_gettable(luaObj , -2);
		printf("Table : %d\n" , lua_tointeger(luaObj , -1));
		lua_pop(luaObj , 1);
		return (Lua_Return_Data){0};
	}else if(lua_isnumber(luaObj , -1)){
		 float data = lua_tonumber(luaObj , -1);
		return (Lua_Return_Data){
			NUMBER,
			(void*)&data
		};
	}else if(lua_isnoneornil(luaObj , -1)){
		return (Lua_Return_Data){
			NIL,
			NULL
		};
	}else if(lua_isboolean(luaObj , -1)){
		 bool data = lua_toboolean(luaObj , -1);
		return (Lua_Return_Data){
			BOOLEAN,
			(void*)&data
		};
	}else if(lua_isfunction(luaObj , -1)){
		 lua_CFunction data = lua_tocfunction(luaObj , -1);
		
		return (Lua_Return_Data){
			FUNCTION,
			(void*)&data
		};
	}else if(lua_isstring(luaObj , -1)){
		const char* data = lua_tostring(luaObj , -1);
		
		return (Lua_Return_Data){
			STRING,
			(void*)data
		};
	}else if(lua_isinteger(luaObj , -1)){
		 long long data = lua_tointeger(luaObj , -1);
		
		return (Lua_Return_Data){
			INTEGER,
			(void*)&data
		};
	}

	// TODO: Handle lua_topointer
	// TODO: Handle lua_touserdata
	// TODO: Handle thread type
	//else if(lua_isthread(luaObj , -1)){
	//	static lua_State* data = lua_tothread(luaObj , -1);
	//	
	//	return (Lua_Return_Data){
	//		STRING,
	//		(void*)&data
	//	};
	//}
}

void print_data_from_lua(Lua_Return_Data data){
	if(data.type == 0){	
		printf("might be failed");
		return ;
	}
	switch(data.type){
		case INTEGER :{
		      printf("data : %lld \n" , *(long long *)data.data);
	        }break;
		case NUMBER : {
		      printf("data : %f \n" , *(float *)data.data);
		}break;
		case NONEORNIL : {
		      printf("data : NULL \n");
 		}break;
		case STRING : {
		      printf("data : %s \n" , (char*)data.data);
		}break;
		default :
			printf("unkonow type");
	}
	return ;
}

int main2(void){
	lua_State *luafile;
	luafile = luaL_newstate();
	luaL_openlibs(luafile);
	if(luaL_loadfile(luafile, "test.lua")){
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));
		return 1;
	}
	if (lua_pcall(luafile, 0, 0, 0) != LUA_OK){
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));
	}
	Lua_Return_Data retdata = read_function_from_lua(luafile , "setup");
	print_data_from_lua(retdata);
	lua_close(luafile);
	return 0;
}

int main(void){

	lua_State *luafile;
	luafile = luaL_newstate();
	luaL_openlibs(luafile);
	if(luaL_loadfile(luafile, "./hello.lua")){
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));
		return 1;
	}

	if (lua_pcall(luafile, 0, 0, 0) != LUA_OK){
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));
	}

	lua_getglobal(luafile , "setup");
	// 0 : params , 1 : for return
	if (lua_pcall(luafile, 0, 1, 0) != LUA_OK)
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

	printf("the return value is : %d" , lua_tointeger(luafile , -1));
	lua_pop(luafile , 1);

	//if(!lua_isnumber(luafile , -1))	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

	//int abdo = lua_tointeger(luafile, -1);
		//lua_pop(luafile , 1);
		//printf("this for abdo %d\n" , abdo);

		//lua_getglobal(luafile , "add");
		//lua_pushnumber(luafile , 7);
		//lua_pushnumber(luafile , 3);
		//// 0 : params , 1 : for return
		//if (lua_pcall(luafile, 2, 1, 0) != LUA_OK)
		//	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

		//if(!lua_isnumber(luafile , -1))	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

		//int add = lua_tointeger(luafile, -1);
		//lua_pop(luafile , 1);
		//printf("this for add %d\n" , add);


	lua_close(luafile);
	 //here the C file will print Hello World 
	 //main.lua contains :
	 //	print("Hello World")

	return 0;
}
