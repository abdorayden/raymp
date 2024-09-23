/*
 *	engine.h is header only library 
 *	contain functions to access and load and run scripts in main program
 *
 *						 ________________
 *		 _____________			|		 |
 *		|             |			| downloader.rmp |
 *		|   ENGINE    | <-------------  | example.rmp	 |
 *		|_____________|			| test.rmp	 |
 *		      |				|________________|
 *		      |
 *		      |
 *		      |
 *		 ________________
 *		|		 |
 *		| Main Program   |
 *		|________________|
 *
 * */

#ifndef RMP_ENGINE
#define RMP_ENGINE

#ifndef RMP_MALLOC
	#define RMP_MALLOC	malloc
#endif

#ifndef RMP_REALLOC
	#define RMP_REALLOC	realloc
#endif

#ifndef RMP_FREE
	#define RMP_FREE	free
#endif

#ifndef RMP_UINT64
	#define RMP_UINT64 unsigned long long 	
#endif

#ifndef RMP_INT64
	#define RMP_INT64	long 
#endif

#ifndef RMP_UINT32
	#define RMP_UINT64 	unsigned int 	
#endif

#ifndef RMP_INT32
	#define RMP_INT64	int
#endif

#ifndef RMP_UINT16
	#define RMP_UINT64 	unsigned short 	
#endif

#ifndef RMP_INT16
	#define RMP_INT64	short
#endif

#ifndef RMP_UINT8
	#define RMP_UINT64 	unsigned char
#endif

#ifndef RMP_INT8
	#define RMP_INT64	char
#endif

// RMP API

#ifdef _WIN32
	#define RMP_DLL_IMPORT  __declspec(dllimport)
	#define RMP_DLL_EXPORT  __declspec(dllexport)
	#define RMP_DLL_PRIVATE static
#else
	#if defined(__GNUC__) && __GNUC__ >= 4
	    	#define RMP_DLL_IMPORT  __attribute__((visibility("default")))
	    	#define RMP_DLL_EXPORT  __attribute__((visibility("default")))
	    	#define RMP_DLL_PRIVATE __attribute__((visibility("hidden")))
	#else
	    	#define RMP_DLL_IMPORT
	    	#define RMP_DLL_EXPORT
	    	#define RMP_DLL_PRIVATE static
	#endif
#endif

#ifndef RMP_API
    #if defined(RMP_DLL)
        #ifdef RMP_ENGINE_IMPLEMENTATION
            #define RMP_API  RMP_DLL_EXPORT
        #else
            #define RMP_API  RMP_DLL_IMPORT
        #endif
    #else
        #define RMP_API extern
    #endif
#endif

// end RMP API

RMP_API void Load_Scripts(void);


#endif // RMP_ENGINE


#ifdef  RMP_ENGINE_IMPLEMENTATION
// implementation
#endif//RMP_ENGINE_IMPLEMENTATION
