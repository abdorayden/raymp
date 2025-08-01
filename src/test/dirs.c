#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>
#include <assert.h>

#define LIST_C
#include "../src/third_party/raylist.h"
#include "../src/log.h"
#define MINIRENT_IMPLEMENTATION
#include "../src/third_party/minirent.h"
#define DIR_ON
#include "../src/rdirectorys.h"

void test_directory(){
	RLList list = List(0);
	InitDir(list);
	ListDir("." , list);

	for(int i = 0 ; i < list.List_Len() ; i++){
		Directoy dir = *(Directoy*)list.List_Get(i);
		printf("%s - %s\n" ,dir.is_dir ? "directory" : "file" , dir.filename);
	}
}

int main(void)
{
	test_directory();
	return 0;
}
