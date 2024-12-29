/************************************************************************************************
*			Copyright (c) 2024 Ray Den	raylist v2.3.0				*
*												*
*	Permission is hereby granted, free of charge, to any person obtaining a copy		*
*	of this software and associated documentation files (the "Software"), to deal		*
*	in the Software without restriction, including without limitation the rights		*
*	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell		*
*	copies of the Software, and to permit persons to whom the Software is			*
*	furnished to do so, subject to the following conditions:				*
*												*
*	The above copyright notice and this permission notice shall be included in		*
*	all copies or substantial portions of the Software.					*
*												*
*	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR		*
*	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,		*	
*	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE		*
*	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER			*
*	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,		*	
*	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN		*
*	THE SOFTWARE.										*
*												*
 ************************************************************************************************/

#if !defined(LIST_H) || !defined(LIST_INCLUDED)
#define LIST_H
#define LIST_INCLUDED 

// to check if raylist is included

// 	typeof pragma returns string contained type of variable
// 	Example :
// 		int var = 4;
// 		printf("typeof(test) : %s" , typeof(var));
// 	Output :
// 		typeof(test) : int

#define typeof(x) _Generic((x),   \
    int		: "int"		, \
    int   *	: "int*"	, \
    float *	: "float*"	, \
    float	: "float"	, \
    double	: "double"	, \
    double*	: "double*"	, \
    char	: "char"	, \
    char  *	: "char*"	, \
    void  *	: "void*"	, \
    short 	: "short"	, \
    short * 	: "short*"	, \
    default	: "unknown"	  \
    )

/*
 *	local type
 * */
#define RLLOCAL	static

/*
 *	if not defined LBOOL the developer not using other boolean style
 *	so we used the defualt 
 * */
#ifndef LBOOL

typedef enum{
	/* by default false take 0 value and that means false 		*/
	false,
	/* not zero that means true 					*/
	true = !(false)
}bool;
#define LBOOL bool

#endif

RLLOCAL LBOOL revesed = false;

/*
 *	check if stdlib is included
 * */

#if !defined(_STDLIB_H)
#include <stdlib.h>
#endif

#if !defined(_STRING_H)
#include <string.h>
#endif


/*
 *	if not defined RLALLOC the developer not using other allocation memory style
 *	so we used the defualt 
 * */


#ifndef RLALLOC
#define RLALLOC	malloc
#endif

#ifndef RLREALLOC
#define RLREALLOC	realloc
#endif

#ifndef RLFREE
#define RLFREE	free
#endif

#ifndef RLUNUSED
#define RLUNUSED(x) (void)x
#endif

#ifndef RLMEMCPY
#define RLMEMCPY	memcpy
#endif

/*
 *	API
 *	this api is used to create thread for multiple operating systems
 *	this api used for running Asynchronous functions
 * */
#ifdef _WIN32

#include <windows.h>
#define RLAPIThread HANDLE
#define RLAPICallBackFunction	LPTHREAD_START_ROUTINE
#define RLAPIParam		LPVOID

#define RLTestCancel()

#else

#ifndef _PTHREAD_H
#include <pthread.h>
#endif

#define RLAPIThread pthread_t
#define RLAPICallBackFunction	void*
#define RLAPIParam		void*

#define RLTestCancel		pthread_testcancel

#endif



// Type enum contained bunch of types helps functions any variables type will work for
// RL_STR for strings RL_BOOL for boolean ... 
typedef enum{
	RL_CHR = 0 , 	// char type
	RL_STR     , 	// string type
	RL_BOOL    ,	// bool type
	RL_INT     , 	// int type
	RL_FLT     , 	// float type
	RL_VOIDPTR ,	// void pointer type

	RL_VOIDFUNC,
	RL_INTFUNC ,
	RL_CHARFUNC,
	RL_STRFUNC
}Type;

typedef enum{
	FINE = 0,
	LIST_INDEX_OUT_OF_RANGE,
	LIST_MEMALLOC,
	NULL_VALUE,
	ERROR_WAIT_THREAD,
	ERROR_KILL_THREAD,
	ERROR_CREATE_THREAD,
	LIST_EMPTY
}ListError;

// global status to handle raylist errors
RLLOCAL ListError status = FINE;

typedef char* string;

/*
 *	the call back function type in list
 * */

typedef void 	(*VOIDFUNCTION		)(void*);
typedef int  	(*INTEGERFUNCTION  	)(void*);
typedef LBOOL 	(*BOOLEANFUNCTION  	)(void*);
typedef char 	(*CHARACTERFUNCTION	)(void*);
typedef string 	(*STRINGFUNCTION 	)(void*);

/*
 *	Linked List struct
 *		index : index of single list
 *		type  : type of the data memory saved in void* data pointer
 *		data  : the place we store the address of our variables 
 *		next  : pointing to next list
 * */

struct list {
	int 		index;
	Type 		type ;
	void* 		data ;
	struct list* 	next ;
};

typedef struct list __List;

#ifndef LIST_MAX
#define LIST_MAX 10
#endif
static int list_index = 0;

// RLDefer is defer function call atexit from stdlib to call function before quit the program
// it does'n work if you press CTRL-C
#define RLDefer		atexit	

/*
 * 	SetObject macro used to change a list object level
 *	IfaceList l = list(0);
 *	IfaceList p = stack(Buf_Disable);
 *	SetObject(1);
 *	start from 1
 *	if the number was 2 it will access p object
 * */
#define RLSetObject(x)								\
	do{									\
		if(!strcmp(typeof(x) , "int") && x < LIST_MAX && x > 0)		\
			list_index = x - 1;					\
	}while(0)								



//    RLCopyObject(size) macro enabled copy value without point to address of the variable
//    this macro is usefull when you try to append struct to your list 
//    and use type RL_VOIDPTR or repeated variable
//    RLDisableCopyObject() do disable it
//
//    Example : 
//    	... // list is already init
//    	RLCopyObject(sizeof(struct MyStruct));
//    	my_list.Append(RL_VOIDPTR , (void*)&my_struct_var);	// append more data with same size
//    	my_list.Append(RL_VOIDPTR , (void*)&my_struct_var);
//    	my_list.Append(RL_VOIDPTR , (void*)&my_struct_var);
//    	RLDisableCopyObject();

RLLOCAL LBOOL enable_copy = false;
RLLOCAL size_t copy_size = 0;
#define RLCopyObject(size)					\
	enable_copy = true;					\
	if((size) < 0)	copy_size = (size) * -1;		\
	else		copy_size = (size);

#define RLDisableCopyObject()					\
	enable_copy = false;					\
	copy_size = 0;						


// Global list variable 
RLLOCAL __List* __list__[LIST_MAX];

// global count for index
RLLOCAL int global_count[LIST_MAX];

// filter callback function 
typedef enum{
	ALL = 0xFF,  	// delete all types 
	ONLY		// only type
}Filter_Flag;

typedef LBOOL (*FILTERCALLBACK)(void*);

// map call back function
typedef void* (*MAPCALLBACK)(void*);

// Exec function Flag
typedef enum {
	/* return value from Exec function
	 * OUTT flag is not enabled if index parameter in Exec_Sync was out of range
	 * */ 
	OUTT, 
	/* the return value will replace function callback index ,
	* the function Exec will run all function 
	* the void function is not replaced 
	* */
	INPLACE,  
	/* the function return value will added to the list */
	ADDED
}Exec_Flag;

/*	definitions 
 *		for more readable code
 *	*/
#define interface 		struct

/*
 *	interface for manipulate thread handle 
 * */
typedef interface {
	// the thread in it self
	RLAPIThread thread;
	/*
	 *	Wait function 
	 *	function waits for the thread specified by thread to terminate
	 * */
	void (*Wait)(RLAPIThread thread);
	/*
	 *	Kill function
	 *	for killing the thread
	 * */
	void (*Kill)(RLAPIThread thread);
}IfaceThread;

/*
 *	this for limit size of stack or queue
 * */
#define Buf_Disable  -1	// NOTE : if this flag is enabled stack or queue will add data dynamic
RLLOCAL int buffer = 0;
RLLOCAL LBOOL limit_buf	= false;

/*
 *	IfaceList struct act like class all thouse functions point to other functions 
 *
 *	Example :
 *		void foo(void){
 *			printf("bar");
 *		}
 *		IfaceList test;
 *		test.List_Append = foo;
 *		
 * */

typedef interface {
#ifndef USING_LIST
	/*
	 *	return true if list is empty else false
	 * */
	LBOOL (*List_Is_Empty)(
			void
	);
	/*
	 *	List_Insert function will take the data and insert at the idx variable it in __list__ global linked list variable
	 *
	 *	List_Insert(
	 *		int idx		: 		index where we insert the data
	 *		Type type	: 		data type
	 *		void* data the  :		data
	 *	)
	 *	Exemple :
	 *		my_list.List_Insert(1 , RL_BOOL , true);
	 * */
	void (*List_Insert)(
			int idx,
			Type type,
			void* data
	);

	/*
	 *	List_Append function will take the data and stored to the __list__ global variable 
	 *
	 * 	List_Append(
	 *		Type : the data type
	 *		void*: data pointer point address of stored data
	 * 	)
	 *	
	 *	NOTE : the append method works like push in stack algorithm
	 *
	 *	Example :
	 *		my_list.List_Append(RL_STR , "Hello World");
	 *
	 * */
	void (*List_Append)(
			Type type,
			void* data
	);
	/*
	 *	List_Filter function takes function callback that returns boolean and filter all elements from the list
	 *
	 *	Example : 
	 *	int check_mod_of_num(void* tch){
	 *		return (*(int*)tch % 2);
	 *	}
	 *	
	 *					before : 	[
	 *								3,2,7,5,1
	 *							]
	 *	my_list.List_Filter(check_mod_of_num , RL_INT);
	 *					after : 	[
	 *								2
	 *							]
	 * */
	void (*List_Filter)(
			FILTERCALLBACK,
			Type , 
			Filter_Flag flag
	);
	/*
	 * 	List_Search function return true if the data has been found and will store index of the data in int* parameter else will return false
	 *
	 *	List_Search(
	 *		int* : integer pointer variable to store index of the data we found
	 *		Type : the data type
	 *		void*: data pointer point address of stored data
	 *	)
	 *
	 *	Example :
	 *		int var;
	 *		if(my_list.List_Search(&var, RL_STR , "Hello World"))	// handle (var contained the index of the data)
	 *		else 							// handle
	 *
	 * */
	LBOOL (*List_Search)(
			int* ,
			Type ,
			void* 
	);
	/*
	 *	List_Del_Index function takes index and delete it from the linked list
	 *
	 *	List_Del_Index(
	 *		int : the index that we want to delete
	 *	)
	 *
	 *	Example :
	 *		my_list.List_Del_Index(3);
	 *
	 * */
	void (*List_Del_Index)(
			int idx 
	);
	/*
	 *	List_Get function takes index parameter and will return void* data  
	 *
	 *	List_Del_Index(
	 *		int : the index of the data we want to get
	 *	)
	 *
	 *	Example :
	 *		void* d = my_list.List_Get(2);
	 *		the data pointer in d variable now 
	 *
	 * */
	void* (*List_Get)(
			int idx
	);

	/*
	 *	List_Reverse function will reverse the list 
	 *
	 * */
	void (*List_Reverse)(
			void
	);
	/*
	 *	List_Print function will print all our data in standerd output 
	 * */

	void (*List_Print)(
			void
	);
	/*
	 * void bar{
	 * 	printf("Hello World");
	 * }
	 * IfaceList my_list = list(0);
	 * my_list.List_Append(RL_VOIDFUNC , bar);
	 * 	the list now contains a function 
	 *  zero for execute function of index 0 , and NULL parameter mean the funtion doesm't accept a parameter
	 * my_list.List_Exec_Sync(0 , NULL);
	 * */

	void* (*List_Exec_Sync)(
			int idx,
			void* data,
			Exec_Flag flag
	);

	// clear list
	void (*List_Clear)(
			void
	);
	/*
	 *  return String if the error is set true (status > 0)
	 * */ 
	string (*List_Get_Error)(
			void
	);
	/*
	 *	map is a higher-order function that applies a given function to each element of a collection
	 *	Example : 
	 *
	 *		void* callback(void* d)
	 *		{
	 *			if(*(int*)d == 2)
	 *			{
	 *				*(int*)d = 10;
	 *			}
	 *			return d;
	 *		}
	 *		IfaceList my_list = list(0);
	 *		for(int i = 0 ; i < 4 ; i++){
	 *			RLAppend(i , RL_INT);
	 *		}
	 *		list : [0,1,2,3]
	 *		my_list.List_Map(callback , RL_INT);
	 *		list : [0,1,10,3]
	 * */ 
	void (*List_Map)(
			MAPCALLBACK	func,
			Type		type
	);
	/*
	 *	exec asynchronous functiona
	 *	IfaceList my_list = list(0);
	 *	my_list.Append(RL_STRFUNC , func);
	 *	my_list.List_Exec_Async(0, NULL).Wait();
	 *
	 * */
	IfaceThread (*List_Exec_Async)(
			int idx,
			RLAPIParam data
	);

	/*
	 *	return length of list
	 * */
	int (*List_Len)(void);
#else
	/*
	 *	Insert function will take the data and insert at the idx variable it in __list__ global linked list variable
	 *
	 *	Insert(
	 *		int idx		: 		index where we insert the data
	 *		Type type	: 		data type
	 *		void* data the  :		data
	 *	)
	 *	Exemple :
	 *		my_list.Insert(1 , RL_BOOL , true);
	 * */
	void (*Insert)(
			int idx,
			Type type,
			void* data
	);
	/*
	 *	Append function will take the data and stored to the __list__ global variable 
	 *
	 * 	Append(
	 *		Type : the data type
	 *		void*: data pointer point address of stored data
	 * 	)
	 *
	 *	Example :
	 *		my_list.Append(RL_STR , "Hello World");
	 *
	 * */
	void (*Append)(
			Type type,
			void* data
	);
	/*
	 *	List_Filter function takes function callback that returns boolean and filter all elements from the list
	 *
	 *	Example : 
	 *	int check_mod_of_num(void* tch){
	 *		return (*(int*)tch % 2);
	 *	}
	 *	
	 *					before : 	[
	 *								3,2,7,5,1
	 *							]
	 *	my_list.List_Filter(check_mod_of_num , RL_INT);
	 *					after : 	[
	 *								2
	 *							]
	 * */
	void (*Filter)(
			FILTERCALLBACK,
			Type , 
			Filter_Flag flag
	);
	/*
	 * 	Search function return true if the data has been found and will store index of the data in int* parameter else will return false
	 *
	 *	Search(
	 *		int* : integer pointer variable to store index of the data we found
	 *		Type : the data type
	 *		void*: data pointer point address of stored data
	 *	)
	 *
	 *	Example :
	 *		int var;
	 *		if(my_list.Search(&var, RL_STR , "Hello World"))	// handle (var contained the index of the data)
	 *		else 							// handle
	 *
	 * */
	LBOOL (*Search)(
			int* ,
			Type ,
			void* 
	);
	/*
	 *	Del_Index function takes index and delete it from the linked list
	 *
	 *	Del_Index(
	 *		int : the index that we want to delete
	 *	)
	 *
	 *	Example :
	 *		my_list.Del_Index(3);
	 *
	 * */
	void (*Del_Index)(
			int idx 
	);
	/*
	 *	Get function takes index parameter and will return void* data  
	 *
	 *	Del_Index(
	 *		int : the index of the data we want to get
	 *	)
	 *
	 *	Example :
	 *		void* d = my_list.Get(2);
	 *		the data pointer in d variable now 
	 *
	 * */
	void* (*Get)(
			int idx
	);

	/*
	 *	Reverse function will reverse the list 
	 *
	 * */
	void (*Reverse)(
			void
	);
	/*
	 *	Print function will print all our data in standerd output 
	 * */
	void (*Print)(
			void
	);
	/*
	 * void bar{
	 * 	printf("Hello World");
	 * }
	 * IfaceList my_list = list(0);
	 * my_list.Append(RL_VOIDFUNC , bar);
	 * 	the list now contains a function 
	 *  zero for execute function of index 0 , and NULL parameter mean the funtion doesm't accept a parameter
	 * my_list.Exec_Sync(0 , NULL);
	 * */

	void* (*Exec_Sync)(
			int idx,
			void* data,
			Exec_Flag flag
	);
	// clear list
	void (*Clear)(
			void
	);
	/*
	 *  return String if the error is set true (status > 0)
	 * */ 
	string (*Get_Error)(
			void
	);
	/*
	 *	map is a higher-order function that applies a given function to each element of a collection
	 *	Example : 
	 *
	 *		void* callback(void* d)
	 *		{
	 *			if(*(int*)d == 2)
	 *			{
	 *				*(int*)d = 10;
	 *			}
	 *			return d;
	 *		}
	 *		IfaceList my_list = list(0);
	 *		for(int i = 0 ; i < 4 ; i++){
	 *			RLAppend(i , RL_INT);
	 *		}
	 *		list : [0,1,2,3]
	 *		my_list.Map(callback , RL_INT);
	 *		list : [0,1,10,3]
	 * */ 
	void (*Map)(
			MAPCALLBACK	func,
			Type		type
	);
	/*
	 *	exec asynchronous functiona
	 *	IfaceList my_list = list(0);
	 *	my_list.Append(RL_STRFUNC , func);
	 *	my_list.List_Exec_Async(0, NULL).Wait();
	 *
	 * */
	IfaceThread (*Exec_Async)(
			int idx,
			RLAPIParam data
	);

	/*
	 *	return length of list
	 * */
	int (*Len)(void);
#endif
}RLList;

// RLCollections interface 
// contains all method , push pop and more for stack and queue data structure
typedef interface {
	/*
	 *	Max_Buffer() return true if buffer equal to fixed buffer else false
	 * */

	LBOOL (*Max_Buffer)(void);

	/*
	 *	return true if stack is empty else false
	 * */
	LBOOL (*Is_Empty)(
			void
	);
	/*
	 *  return String if the error is set true (status > 0)
	 * */ 
	string (*Get_Error)(
			void
	);
	/*
	 *	Push function will take the data and stored to the __list__ global variable 
	 *
	 * 	Push(
	 *		Type : the data type
	 *		void*: data pointer point address of stored data
	 * 	)
	 *	
	 *	NOTE : the append method works like push in stack algorithm
	 *
	 *	Example :
	 *		my_list.Push(RL_STR , "Hello World");
	 *
	 * */
	void (*Push)(
			Type type,
			void* data
	);
	/*
	 *	Peek function return last value of the Stack (Stack)
	 *	Example : 
	 *		void* value = my_list.Stack_Peek();
	 * */
	void* (*Peek)(void);
	/*
	 *	Stack_Pop function will pop the last value from the list
	 *
	 *	Example : 
	 *		void* value = my_list.Stack_Pop();
	 * */
	void* (*Pop)(void);
	// clear Stack
	void (*Clear)(
			void
	);

}RLCollections;


RLList List(
		int count , 	// number of data you
		... 		// data : <TYPE> , <VALUE>
);

RLCollections Stack(int buffer_size);

RLCollections Queue(int buffer_size);

#endif

#ifdef LIST_C

/*
 *	api function 
 * */
RLLOCAL RLAPIThread RLCreateThread(RLAPICallBackFunction func , RLAPIParam parameter)
{
#ifndef _WIN32
	RLAPIThread thread;
	if(pthread_create(&thread, NULL, func, parameter) == 0)
	{
		status = ERROR_CREATE_THREAD;
		return thread;
	}
#else
	RLAPIThread thread = CreateThread(NULL , 0 , func , parameter , 0 , NULL);
	if(thread == NULL){
		status = ERROR_CREATE_THREAD;
		return NULL ;
	}
#endif
	return thread;
}

RLLOCAL void RLWait(RLAPIThread thread)
{
#ifdef _WIN32
	if(WaitForSingleObject(thread , INFINITE) == WAIT_FAILED)
	{
		status = ERROR_WAIT_THREAD;
		return;
	}
#else
	if(pthread_join(thread , NULL) != 0)
	{
		status = ERROR_WAIT_THREAD;
		return;
	}
#endif
}

/*
 * NOTE : in Callback function don't forget to call RLTestCancel() function 
 * to enable kill thread
 * */

RLLOCAL void RLKill(RLAPIThread thread)
{
#ifdef _WIN32
	if(!TerminateThread(thread , 0))
	{
		status = ERROR_KILL_THREAD;
		return;
	}
	CloseHandle(thread);
#else
	if(pthread_cancel(thread) != 0)
	{
		status = ERROR_WAIT_THREAD;
		return;
	}
#endif
}

RLLOCAL void add_voidptr(
		__List** __list__ , 
		void* val , 
		Type t, 
		int idx
){
	__List* temp = RLALLOC(sizeof(__List));
	if(temp == NULL)
	{
		status = LIST_MEMALLOC;
		return;
	}
	if(!enable_copy)
		temp->data = val;  
	else {
		temp->data = RLALLOC(copy_size + 1);
		RLMEMCPY(temp->data , val , copy_size + 1);
	}
	temp->type = t;                 
	temp->index = idx;              
	temp->next = *__list__;                
	*__list__ = temp;                      
}
RLLOCAL void add_int(
		__List** __list__ , 
		int val , 
		Type t, 
		int idx
){
	__List* temp = RLALLOC(sizeof(__List));
	if(temp == NULL)
	{
		status = LIST_MEMALLOC;
		return;
	}
	temp->data = RLALLOC(sizeof(int));
	*(int*)temp->data = val;
	temp->type = t;                 
	temp->index = idx;              
	temp->next = *__list__;                
	*__list__ = temp;                      
}

RLLOCAL void add_char(
		__List** __list__ , 
		char val , 
		Type t, 
		int idx
){
	__List* temp = RLALLOC(sizeof(__List));
	if(temp == NULL)
	{
		status = LIST_MEMALLOC;
		return;
	}
	temp->data = RLALLOC(sizeof(char));
	*(char*)temp->data = val;
	temp->type = t;                 
	temp->index = idx;              
	temp->next = *__list__;                
	*__list__ = temp;                      
}

RLLOCAL void add_float(
		__List** __list__ , 
		float val , 
		Type t, 
		int idx
){
	__List* temp = RLALLOC(sizeof(__List));
	if(temp == NULL)
	{
		status = LIST_MEMALLOC;
		return;
	}
	temp->data = RLALLOC(sizeof(float));
	*(float*)(temp->data) = val;
	temp->type = t;                 
	temp->index = idx;              
	temp->next = *__list__;                
	*__list__ = temp;                      
}

#define add(l , v , t , i) _Generic((v) ,	 	\
			int : add_int,			\
			char : add_char,		\
			float : add_float,		\
			default : add_voidptr		\
		)(l , v , t , i);

RLLOCAL void init(void){
	for(int x = 0 ; x < LIST_MAX ; x++){
		__list__[x] = NULL;
		global_count[x] = 0;
	}
}

RLLOCAL LBOOL l_is_empty(void)
{
	return (global_count[list_index] == 0);
}

// the complexity still O(N) in worst case the index helps you to know the data u want to get later
RLLOCAL void local_l_insert(__List** __list__ , int idx , Type type , void* data){
	__List* local_list = *(__list__);

	if(idx < global_count[list_index] && idx >= 0){
		while(local_list != NULL){
			if(local_list->index > idx){	
				local_list->index++;
			}
			if(idx == local_list->index){
				__List* node = RLALLOC(sizeof(__List));
				if(node == NULL)
				{
					status = LIST_MEMALLOC;
					return;
				}
				node->data = data;
				node->type = type;
				node->index = idx;

				local_list->index++;
				__List* temp = local_list->next;
				local_list->next = node;
				node->next = temp;
				if(local_list->next != NULL)
					local_list = local_list->next;
			}

			local_list = local_list->next;
		}
		global_count[list_index]++;
	}else{
		add(__list__ ,data , type , global_count[list_index]++);
	}
}
RLLOCAL void* l_peek(void)
{
	return __list__[list_index]->data;
}

RLLOCAL LBOOL l_max_buf(){
	return (limit_buf && buffer == global_count[list_index]);
}

RLLOCAL int l_len(){
	return global_count[list_index];
}

RLLOCAL void* l_qpeek(void)
{
	__List* temp = __list__[list_index];
	while(temp->next != NULL)	temp = temp->next;
	return temp->data;
}

RLLOCAL void* local_l_qpop(__List** __list__){
	void* d;
	if(*__list__ == NULL){
		return NULL;
	}
	__List* ___temp = *__list__;
	if((___temp)->next == NULL){
		d = ___temp->data;
		RLFREE(___temp);
		*__list__ = NULL;
		global_count[list_index]--;
		return d;
	}
	while((___temp)->next->next != NULL)	___temp = (___temp)->next;
	d = ___temp->next->data;
	RLFREE(___temp->next);
	___temp->next = NULL;
	global_count[list_index]--;
	return d;
}

RLLOCAL void* l_qpop(){
	return local_l_qpop(&__list__[list_index]);
}

RLLOCAL void* local_l_pop(__List** __list__){
	void* ret;
	__List* temp = *__list__;
	if(temp == NULL)	return NULL;
	ret = temp->data;
	*__list__ = (*__list__)->next;
	RLFREE(temp);
	global_count[list_index]--;
	return ret;
}

RLLOCAL void* l_pop(){
	return local_l_pop(&__list__[list_index]);
}

RLLOCAL void l_insert(int idx , Type type , void* data){
	local_l_insert(&__list__[list_index] , idx , type , data);
}


#define RLAppend(t , d) _Generic((d) , 		\
			int : add_int,		\
			char : add_char,	\
			float : add_float,	\
			default : add_voidptr		\
		)(&__list__[list_index] , d , t  , global_count[list_index]++);

#define RLPush(t , d) 												\
	do{													\
		if(limit_buf){											\
			if(global_count[list_index] < buffer){							\
				_Generic((d) ,	 								\
					int : add_int,								\
					char : add_char,							\
					float : add_float,							\
					default : add_voidptr							\
				)(&__list__[list_index] , d , t  , global_count[list_index]++);			\
			}											\
		}else{												\
				_Generic((d) ,	 								\
					int : add_int,								\
					char : add_char,							\
					float : add_float,							\
					default : add_voidptr							\
				)(&__list__[list_index] , d , t  , global_count[list_index]++);			\
		}												\
	}while(0)

RLLOCAL void l_append(
		Type type,
		void* data
)
{
	if(status != FINE) status = FINE;
	add(&__list__[list_index] , data, type , global_count[list_index]++);
}

RLLOCAL void l_push(
		Type type,
		void* data
)
{
	if(status != FINE) status = FINE;
	if(limit_buf){
		if(global_count[list_index] < buffer)
			add(&__list__[list_index] , data, type , global_count[list_index]++);
	}else{
		add(&__list__[list_index] , data, type , global_count[list_index]++);
	}
}

RLLOCAL void l_clear(void){
	for(int x = 0 ; x < list_index ; x++){
		__List* current = __list__[x];
		__List* temp;
		while (current != NULL) {
			temp = current->next; 
			RLFREE(current);        
			current = temp;       
		}
	}
	init();
	revesed = false;
}
RLLOCAL void* local_exec(__List* __list__ ,int idx , void* data , Exec_Flag flag)
{
	if(idx > global_count[list_index]){	
		status = LIST_INDEX_OUT_OF_RANGE;
		return NULL;
	
	}else if(__list__ == NULL){
		status = LIST_EMPTY;
		return NULL;
	}else{
		status = FINE;
	}
	if(idx < 0 || idx > global_count[list_index]){
		while(__list__ != NULL){
			switch((__list__)->type){
				// NOTE : OUTT flag will not work in that case
				// return value will block the loop
				case  RL_VOIDFUNC:{
					if(data == NULL){
						void (*call)() = (void(*)())(__list__)->data;
						call();
					}else{
						void (*call)(void*) = (void(*)(void*))(__list__)->data;
						call(data);
					}
				}break; 
				case RL_CHARFUNC : {
					if(data == NULL){
						char* (*call)() = ((char*(*)())(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_CHR;
							__list__->data = (char*)call();
						}else{
							l_append(RL_CHR , (void*)call());
						}
					}else{
						char* (*call)(void*) = ((char*(*)(void*))(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_CHR;
							__list__->data = (char*)call(data);
						}else{
							l_append(RL_CHR , (void*)call(data));
						}
					}
				}break;
				case RL_INTFUNC : {
					if(data == NULL){
						int* (*call)() = ((int*(*)())(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_INT;
							__list__->data = (int*)call();
						}else{
							l_append(RL_INT , (void*)call());
						}
					}else{
						int* (*call)(void*) = ((int*(*)(void*))(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_INT;
							__list__->data = (int*)call(data);
						}else{
							l_append(RL_INT , (void*)call(data));
						}
					}
				}break;
				case RL_STRFUNC : {
					if(data == NULL){
						string (*call)() = ((string(*)())(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_STR;
							__list__->data = (string)call();
						}else{
							l_append(RL_STR , (void*)call());
						}
					}else{
						string (*call)(void*) = ((string(*)(void*))(__list__)->data);
						if(flag == INPLACE) {
							__list__->type = RL_STR;
							__list__->data = (string)call(data);
						}else{
							l_append(RL_STR , (void*)call(data));
						}
					}
				}break;
				default :{ 	
					__list__ = (__list__)->next;
					continue;
				}
			}
			__list__ = (__list__)->next;
		}
	}else{
		while(__list__ != NULL){
			if((__list__)->index == idx){
				switch((__list__)->type){
					case RL_STRFUNC : {
						if(data == NULL){
							string (*call)() = ((string(*)())(__list__)->data);
							if(flag == OUTT)
								return (char*)call();
							else if(flag == INPLACE) {
								__list__->type = RL_STR;
								__list__->data = (string)call();
							}else{
								l_append(RL_STR , (void*)call());
							}
							return NULL;
						}else{
							string (*call)(void*) = ((string(*)(void*))(__list__)->data);
							if(flag == OUTT){
								return (string)call(data);
							}
							else if(flag == INPLACE) {
								__list__->type = RL_STR;
								__list__->data = (char*)call(data);
							}else{
								l_append(RL_STR , (void*)call(data));
							}
							return NULL;
						}
					}break;
					case RL_CHARFUNC : {
						// NOTE : callback function can't return local address variable 
						// 		declare global variable or declare it as static
						if(data == NULL){
							char* (*call)() = ((char*(*)())(__list__)->data);
							if(flag == OUTT){
								return (void*)call();
							}
							else if(flag == INPLACE) {
								__list__->type = RL_CHR;
								__list__->data = (char*)call();
							}else{
								l_append(RL_CHR , (void*)call());
							}
						}else{
							char* (*call)(void*) = ((char*(*)(void*))(__list__)->data);
							if(flag == OUTT){
								return (char*)call(data);
							}
							else if(flag == INPLACE) {
								__list__->type = RL_INT;
								__list__->data = (char*)call(data);
							}else{
								l_append(RL_CHR , (void*)call(data));
							}
						}
					}break;
					case RL_INTFUNC : {
						// NOTE : callback function can't return local address variable 
						// 		declare global variable or declare it as static
						if(data == NULL){
							int* (*call)() = ((int*(*)())(__list__)->data);
							if(flag == OUTT){
								return (void*)call();
							}
							else if(flag == INPLACE) {
								__list__->type = RL_INT;
								__list__->data = (int*)call();
							}else{
								l_append(RL_INT , (void*)call());
							}
						}else{
							int* (*call)(void*) = ((int*(*)(void*))(__list__)->data);
							if(flag == OUTT){
								return (int*)call(data);
							}
							else if(flag == INPLACE) {
								__list__->type = RL_INT;
								__list__->data = (int*)call(data);
							}else{
								l_append(RL_INT , (void*)call(data));
							}
						}
					}break;
					case  RL_VOIDFUNC:{
						if(data == NULL){
							void (*call)() = (void(*)())(__list__)->data;
							call();
						}else{
							void (*call)(void*) = (void(*)(void*))(__list__)->data;
							call(data);
						}
						return NULL;
					}break; 
					default :{ 
						__list__ = (__list__)->next;
						continue;
					}
				}
			}
			__list__ = (__list__)->next;
		}
	}
	return NULL;
}

RLLOCAL void* exec(int idx , void* data , Exec_Flag flag){
	return local_exec(__list__[list_index] , idx , data , flag);
}

RLLOCAL void local_l_popidx(
		__List** __list__,
		int idx
		)
{
	if(*__list__ == NULL){
		status = LIST_EMPTY;
		return;
	}
	if(idx > global_count[list_index] || idx < 0)
	{
		status = LIST_INDEX_OUT_OF_RANGE;
		return;
	}
	status = FINE;
	__List* ___temp = *__list__;
	__List* prev = NULL;
	if (___temp != NULL && ___temp->index == idx) {
	    *__list__ = ___temp->next;
	    RLFREE(___temp);
	    ___temp = *__list__;
	    while(___temp != NULL && revesed){
	        ___temp->index--;
	        ___temp =  ___temp->next;
	    }
	    global_count[list_index]--;
	    return;
	}
	while (___temp != NULL && ___temp->index != idx) {
		if(!revesed && ___temp->index > 0)
			___temp->index--;
		prev = ___temp;
		___temp = ___temp->next;
	}
	if (___temp == NULL) {
	    return;
	}
	prev->next = ___temp->next;
	RLFREE(___temp);
	___temp = prev->next;
	while(revesed && ___temp != NULL && ___temp->index > 0){
		___temp->index--;
		___temp =  ___temp->next;
	}
	global_count[list_index]--;
}
RLLOCAL void l_delete(int idx)
{
	local_l_popidx(&__list__[list_index] , idx);
}

RLLOCAL void l_filter(FILTERCALLBACK callback , Type type , Filter_Flag flag){
	__List* ___temp = __list__[list_index];
	while(___temp != NULL){
		if(___temp->type == type){
			if(!callback(___temp->data)){
				l_delete(___temp->index);
			}
		}else if(flag == ALL){
			l_delete(___temp->index);
		}
		___temp = ___temp->next;
	}
}

RLLOCAL void l_map(MAPCALLBACK callback , Type type){
	__List* ___temp = __list__[list_index];
	while(___temp != NULL){
		if(___temp->type == type){
			___temp->data = callback(___temp->data);
		}
		___temp = ___temp->next;
	}
}

RLLOCAL void wait(RLAPIThread thread){
	RLWait(thread);
}
RLLOCAL void kill(RLAPIThread thread)
{
	RLKill(thread);
}

RLLOCAL IfaceThread exec_async(int idx , RLAPIParam data){
	__List* ___temp = __list__[list_index];

	IfaceThread th = {0};

	if(___temp == NULL)
	{
		status = NULL_VALUE;
		return th;
	}

	if(idx < 0 || idx > global_count[list_index]){
		status = LIST_INDEX_OUT_OF_RANGE;
		return th;
	}

	while(___temp != NULL)
	{
		if(___temp->index == idx){
			RLAPIThread thread = RLCreateThread(___temp->data , data);
			th.thread = thread;
			th.Wait = wait;
			th.Kill = kill;
			break;
		}
		___temp = ___temp->next;
	}
	return th;
}

RLLOCAL string l_geterror()
{
	switch(status){
		case LIST_INDEX_OUT_OF_RANGE : return "[ERROR] list index out of range";
		case LIST_EMPTY : return "[ERROR] list empty";
		case LIST_MEMALLOC : return "[ERROR] list allocating memory";
		case NULL_VALUE : return "[ERROR] NULL value detected";
		case ERROR_CREATE_THREAD : return "[ERROR] create thread , use GetLastError() or check errorno code ";
		case ERROR_WAIT_THREAD : return "[ERROR] wait thread , use GetLastError() or check errorno code ";
		case ERROR_KILL_THREAD : return "[ERROR] kill thread , use GetLastError() or check errorno code ";
		default : return NULL;
	}
}

RLLOCAL void* local_l_get(__List* __list__ , int idx)
{
	if(__list__ == NULL){
		status = LIST_EMPTY;
		return NULL;
	}
	if(idx > global_count[list_index] || idx < 0){
		status = LIST_INDEX_OUT_OF_RANGE;
		return NULL;
	}
	__List* local_list = __list__;
	status = FINE;
	while(local_list != NULL){
		if((local_list)->index == idx){	
			return (local_list)->data;
			break;
		}
		local_list = (local_list)->next;
	}
	status = NULL_VALUE;
	return NULL;
}
RLLOCAL void* l_get(int idx){
	return local_l_get(__list__[list_index] , idx);
}
RLLOCAL LBOOL local_l_search(
		__List* __list__,
		int* idx ,
		Type type ,
		void* data
)
{
	__List* ___temp = __list__;
	if(___temp == NULL){
		status = LIST_EMPTY;
		return false;
	}
	status = FINE;
	while(___temp != NULL){
		switch(type){
			case RL_STR :{
				if(data == ___temp->data){
					if(idx != NULL)
						*idx = ___temp->index ;
					return true;
				}
			}break;
			case RL_CHR :
			case RL_INT:{
				if(*((int*)data) == (*(int*)___temp->data)){
					if(idx != NULL)
						*idx = ___temp->index ;
				 	return true;
				}
			}break;
			case RL_FLT: {
				if(*(float*)data == *(float*)___temp->data){
					if(idx != NULL)
						*idx = ___temp->index ;
				 	return true;
				}
			}break;
			case RL_BOOL:{
				if(*(LBOOL*)data){
					if(idx != NULL)
						*idx = ___temp->index ;
				 	return true;
				}
			}break;
			default : {
				___temp = ___temp->next;
				continue;
			 }
		}
		___temp = ___temp->next;
	}
	return false;
}
RLLOCAL LBOOL l_search(
		int* idx ,
		Type type ,
		void* data
	     )
{
	return local_l_search(__list__[list_index] , idx , type , data);
}
RLLOCAL void local_l_reverse(__List** __list__)
{
	if((*__list__) == NULL){
		status = LIST_EMPTY;
		return;
	}
	status = FINE;
	__List* prev = NULL; 
	__List* current = *__list__; 
	__List* next = NULL; 
	while (current != NULL) { 
	    next = current->next; 
	    current->next = prev; 
	    prev = current; 
	    current = next; 
	} 
	*__list__ = prev; 
	revesed = !revesed;
}
void l_reverse(){
	local_l_reverse(&__list__[list_index]);
}
void l_print()
{
	if(__list__[list_index] == NULL){	
		printf("[NULL]");
		status = LIST_EMPTY;
		return ;
	}
	__List* local_list = __list__[list_index];
	status = FINE;
	//local_l_reverse(&local_list);
	printf("[\n");
	while(local_list != NULL){
		switch((local_list)->type){
			case RL_CHR:{
				printf("\n\t[%d] '%c'",(local_list)->index  ,(*(char*)(local_list)->data) );
			}break;
			case RL_INT:{
				printf("\n\t[%d] %d",(local_list)->index  ,(*(int*)(local_list)->data) );
			}break;
			case RL_FLT:{
				printf("\n\t[%d] %f",(local_list)->index  ,(*(float*)(local_list)->data) );
			}break;

			case RL_STR:{
				printf("\n\t[%d] \"%s\"",(local_list)->index  , (char*)(local_list)->data);
			}break;
			case RL_BOOL:{
				printf("\n\t[%d] %s",(local_list)->index  , *(int*)(local_list)->data ? "true" : "false");
			}break;
			case RL_VOIDPTR :{
				// printing address of the void ptr
				printf("\n\t[%d] %p",(local_list)->index , (local_list)->data);
			}break;
			case  RL_INTFUNC:{
				printf("\n\t<int function : %p><index : %d>" ,(local_list)->data,(local_list)->index);
			}break; 
			case  RL_CHARFUNC:{
				printf("\n\t<character function : %p><index : %d>", (local_list)->data,(local_list)->index);
			}break; 
			case  RL_STRFUNC :{
				printf("\n\t<string function : %p><index : %d>", (local_list)->data,(local_list)->index);
			}break; 
			case  RL_VOIDFUNC:{
				printf("\n\t<void function : %p><index : %d>" ,(local_list)->data,(local_list)->index);
			}break;

		}
		(local_list) = (local_list)->next;
		if((local_list) != NULL)	printf(",");
	}
	printf("\n]\n");
}

RLList List(int count , ...)
{
	init();
	va_list args;
	va_start(args , count);

	RLList cl;
	global_count[list_index] = count;
	int c = 0;
	while(c < count){
		Type t = va_arg(args , Type);
		switch(t){
			case RL_CHR:{
				void* temp = va_arg(args , char*);
				add(&__list__[list_index],temp, RL_CHR , c);
			}break;
			case RL_INT:{
				void* temp= va_arg(args , void*);
				add(&__list__[list_index],temp, RL_INT , c);
			}break;
			case RL_STR:{
				void* temp = va_arg(args , char*);
				add(&__list__[list_index],temp , RL_STR , c);
			}break;
			case RL_BOOL:{
				void* t = va_arg(args , void*);
				void* temp = *(int*)t == true ? "true" : "false";
				add(&__list__[list_index],temp, RL_BOOL , c);
			}break;
			case RL_FLT:{
				void* temp = va_arg(args , void*);
				float* ttemp = (float*)temp;
				add(&__list__[list_index],ttemp , RL_FLT , c);
			}break;
			case RL_VOIDPTR :{
				void* temp = va_arg(args , void*);
				add(&__list__[list_index],temp , RL_VOIDPTR , c);
			}break;
			case  RL_VOIDFUNC:{
				VOIDFUNCTION temp = va_arg(args ,VOIDFUNCTION);
				add(&__list__[list_index],(void*)temp , RL_VOIDFUNC , c);
			}break; 
			case  RL_INTFUNC :{
				INTEGERFUNCTION temp = va_arg(args ,INTEGERFUNCTION);
				add(&__list__[list_index],(void*)temp , RL_INTFUNC , c);
			}break;
			case  RL_CHARFUNC:{
				CHARACTERFUNCTION temp = va_arg(args ,CHARACTERFUNCTION);
				add(&__list__[list_index],(void*)temp , RL_CHARFUNC , c);
			}break;
			case  RL_STRFUNC :{
				STRINGFUNCTION temp = va_arg(args ,STRINGFUNCTION);
				add(&__list__[list_index],(void*)temp , RL_STRFUNC , c);
			}break; 
		}
		c++;
	}
	if(c == 0)	status = LIST_EMPTY;
	va_end(args);
#ifndef USING_LIST
	cl.List_Is_Empty = l_is_empty;
	cl.List_Insert = l_insert;
	cl.List_Append = l_append;
	cl.List_Del_Index = l_delete;
	cl.List_Get = l_get;
	cl.List_Search = l_search;
	cl.List_Reverse = l_reverse;
	cl.List_Print = l_print;
	cl.List_Exec_Sync = exec;
	cl.List_Clear = l_clear;
	cl.List_Get_Error = l_geterror;
	cl.List_Filter = l_filter;
	cl.List_Map = l_map;
	cl.List_Exec_Async = exec_async;
	cl.List_Len = l_len;
#else
	cl.Insert = l_insert;
	cl.Append = l_append;
	cl.Del_Index = l_delete;
	cl.Get = l_get;
	cl.Search = l_search;
	cl.Reverse = l_reverse;
	cl.Print = l_print;
	cl.Exec_Sync = exec;
	cl.Clear = l_clear;
	cl.Get_Error = l_geterror;
	cl.Filter = l_filter;
	cl.Map = l_map;
	cl.Exec_Async = exec_async;
	cl.Len = l_len;
#endif
	return cl;
}

RLCollections Stack(int buffer_size)
{
	init();
	if(buffer_size != Buf_Disable){
		limit_buf = true;
		buffer = buffer_size;
	}

	RLCollections cl;
	global_count[list_index] = 0;

	cl.Max_Buffer = l_max_buf;
	cl.Is_Empty = l_is_empty;
	cl.Push = l_push;
	cl.Clear = l_clear;
	cl.Peek = l_peek;
	cl.Pop = l_pop;
	cl.Get_Error = l_geterror;

	return cl;
}

RLCollections Queue(int buffer_size)
{
	init();
	if(buffer_size != Buf_Disable){
		limit_buf = true;
		buffer = buffer_size;
	}

	RLCollections cl;
	global_count[list_index] = 0;

	cl.Max_Buffer = l_max_buf;
	cl.Pop = l_qpop;
	cl.Peek = l_qpeek;
	cl.Is_Empty = l_is_empty;
	cl.Push = l_push;
	cl.Clear = l_clear;
	cl.Get_Error = l_geterror;

	return cl;
}

#endif /* LIST_C */

